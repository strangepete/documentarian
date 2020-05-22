### Documentarian

## A document generation tool for Janet projects

## by Michael Camilleri
## 10 May 2020

## Thanks to Andrew Chambers for his feedback and suggestions.


(import argparse)
(import spork/misc :as spork)
(import musty)


(def- sep (if (= :windows (os/which)) "\\" "/"))
(var- include-private? false)


(def- arg-settings
  ["A document generation tool for Janet projects."
   "defix" {:kind :option
            :short "d"
            :help "Remove a directory name from function names."
            :default "src"}
   "echo"  {:kind :flag
            :short "e"
            :help "Prints output to stdout."}
   "input" {:kind :option
            :short "i"
            :help "Specify the project file."
            :default "project.janet"}
   "output" {:kind :option
             :short "o"
             :help "Specify the output file."
             :default "api.md"}
   "private" {:kind :flag
              :short "p"
              :help "Include private values."}])


(def- template
  (spork/dedent
    ````
    # {{module}} API

    {{#elements}}
    {{^first}}, {{/first}}[{{name}}](#{{in-link}})
    {{/elements}}

    {{#elements}}
    ## {{name}}

    **{{kind}}** {{#private?}}| **private**{{/private?}} {{#link}}| [source][{{num}}]{{/link}}

    {{#sig}}
    ```janet
    {{&sig}}
    ```
    {{/sig}}

    {{&docstring}}

    {{#link}}
    [{{num}}]: {{link}}
    {{/link}}

    {{/elements}}
    ````))


(defn- link
  ```
  Create a link to a specific line in a file
  ```
  [{:file file :line line} local-parent remote-parent]
  (if (nil? file)
    nil
    (if (and local-parent remote-parent (not (empty? local-parent)))
      (-> (string/replace local-parent remote-parent file)
          (string "#L" line))
      (string file "#L" line))))


(defn item->element
  ```
  Prepare the fields for the template
  ```
  [item num opts]
  {:num       num
   :first     (one? num)
   :name      (string (item :ns) (item :name))
   :kind      (string (item :kind))
   :private?  (item :private?)
   :sig       (or (item :sig)
                  (and (not (nil? (item :value)))
                       (string/format "%q" (item :value))))
   :docstring (item :docstring)
   :link      (link item (opts :local-parent) (opts :remote-parent))
   :in-link   (->> (string (item :ns) (item :name))
                   (string/replace-all "/" "")
                   (string/replace-all "!" "")
                   (string/replace-all "?" ""))})


(defn items->markdown
  ```
  Create the Markdown-formatted strings
  ```
  [items module-name opts]
  (let [elements (seq [i :range [0 (length items)]]
                   (item->element (items i) (+ 1 i) opts))]
    (musty/render template {:module module-name :elements elements})))


(defn- source-map
  ```
  Determine the source-map for a given set of metadata
  ```
  [meta]
  (if (meta :source-map)
    (meta :source-map)
    [nil nil nil]))


(defn- item-details
  ```
  Create a table of metadata
  ```
  [name ns meta]
  (let [value           (or (meta :value) (first (meta :ref)))
        [file line col] (source-map meta)
        kind            (if (meta :macro) :macro (type value))
        private?        (meta :private)
        docs            (meta :doc)
        [sig docstring] (if (and docs (string/find "\n\n" docs))
                          (->> (string/split "\n\n" docs 0 2)
                               (map spork/dedent))
                          [nil docs])]
    {:name      name
     :ns        ns
     :value     value
     :kind      kind
     :private?  private?
     :sig       sig
     :docstring docstring
     :file      file
     :line      line}))


(defn bindings->items
  ```
  Convert the data structure used by Janet to a simple table
  ```
  [set-of-bindings]
  (def items @[])
  (each [filename bindings] (pairs set-of-bindings)
    (def ns (string (string/replace ".janet" "" filename) "/"))
    (each [name meta] (pairs bindings)
      (if (or (not (get meta :private))
              include-private?)
        (array/push items (item-details name ns meta)))))
  (sort-by (fn [item] (get item :name)) items))


(defn extract-bindings
  ```
  Extract the bindings for sources
  ```
  [source source-path]
  (when (string/has-suffix? ".janet" source)
    (let [path     (string/replace ".janet" "" source)
          bindings (require path)
          file     (if (empty? source-path)
                     source
                     (string/replace source-path "" source))]
      (each k [:current-file :source] (put bindings k nil))
      {file bindings})))


(defn gather-files
  ```
  Replace mixture of files and directories with files
  ```
  [paths &opt parent]
  (default parent "")
  (mapcat
    (fn [path]
      (let [p (string parent path)]
        (case (os/stat p :mode)
          :file
          p

          :directory
          (gather-files (os/dir p) (string p sep)))))
    paths))


(defn- validate-project-data
  ```
  Check that the data in the project.janet file includes everything we need
  ```
  [data]
  (unless (and (get data :project)
               (get data :source))
    (error "Project file must contain declare-project and declare-source"))
  data)


(defn parse-project
  ```
  Parse a project.janet file

  This function returns a table of the values in the project file. The keys are
  the sections but without the leading `declare-` and inserted as keywords.
  ```
  [project-file]
  (let [contents (slurp project-file)
        p        (parser/new)
        result    @{}]
    (parser/consume p contents)
    (while (parser/has-more p)
      (let [form (parser/produce p)
            head (first form)
            tail (tuple/slice form 1)]
        (when (string/has-prefix? "declare-" head)
          (let [key (-> (string/replace "declare-" "" head) keyword)]
            (put result key (struct ;tail))))))
    (validate-project-data result)))


(defn- detect-dir
  ```
  Determine the project directory relative to the path to the project file
  ```
  [project-file]
  (let [seps (string/find-all sep project-file)]
    (if (empty? seps)
      ""
      (string/slice project-file 0 (+ 1 (array/peek seps))))))


(defn- generate-doc
  ```
  Generate the document based on various inputs
  ```
  [&keys {:echo echo?
          :output output-file
          :private private
          :project project-file
          :source-dir source-dir}]
  (when private
    (set include-private? true))

  (def project-path (detect-dir project-file))
  (def source-path (string project-path (if (empty? source-dir)
                                          ""
                                          (string source-dir sep))))

  (def project-data (parse-project project-file))

  (def name (get-in project-data [:project :name]))
  (def sources (-> (get-in project-data [:source :source]) (gather-files project-path)))

  (def bindings (reduce (fn [b s] (merge b (extract-bindings s source-path))) @{} sources))
  (def items (bindings->items bindings))
  (def document (items->markdown items name {:local-parent project-path
                                             :remote-parent ""}))

  (if echo?
    (print document)
    (spit output-file document)))


(defn main
  [& args]
  (let [result (argparse/argparse ;arg-settings)]
    (unless result
      (os/exit 1))
    (generate-doc :echo (result "echo")
                  :output (result "output")
                  :private (result "private")
                  :project (result "input")
                  :source-dir (result "defix"))))
