(module nano-copilot
  {autoload {core aniseed.core
             nvim aniseed.nvim
             str aniseed.string
             util slim.nvim
             curl plenary.curl
             lsps lsps}
   require {dockerai dockerai
            job plenary.job}})

(defn open [lines]
  (let [buf (vim.api.nvim_create_buf false true)]
    (nvim.buf_set_text buf 0 0 0 0 lines) 
    (util.open-win buf {:title "Copilot"})))

(comment
  (open ["hey"]))

(defn openselection []
  (open (util.get-current-buffer-selection)))

;(nvim.set_keymap :v :<leader>ai ":lua require('nano-copilot').openselection()<CR>" {})

;;; --------

(defn ollama [system-prompt prompt cb]
  (curl.post 
    "http://localhost:11434/api/generate"
    {:body (vim.json.encode {:model "llama2"
                             :prompt prompt
                             :system system-prompt 
                             :stream true})
     :stream (fn [_ chunk _]
               (cb (. (vim.json.decode chunk) "response")))}))

(defn execute-prompt [prompt]
  (util.stream-into-buffer (partial ollama "") prompt))

(defn execute-rag-prompt [prompt]
  (util.stream-into-buffer
    (fn [prompt cb]
      (let [j (job:new 
                {:command "/Users/slim/slimslenderslacks/hackathon/bin/python3"
                 :args ["rag.py" prompt]
                 :on_stdout (fn [_ line] (cb line))
                 :on_stderr (fn [_ line] (cb line))
                 :on_exit (fn [])})]
        (job.start j)))
    prompt))

(comment
  (execute-prompt "What does a Dockerfile look like?")
  (vim.fn.input "Question: "))

;; ----------

(defn copilot []
  (let [prompts ["run base LLM"
                 "run augmented LLM"]]
    (vim.ui.select
      prompts
      {:prompt "Select LLM"}
      (fn [selected _]
        (let [prompt (..
                       "I have a question about this: "
                       (vim.fn.input "Question: ")       
                       "\n\n Here is the code:\n```\n"
                       (str.join "\n" (util.get-current-buffer-selection))
                       "\n```\n")]
          (if 
            (= selected "run base LLM")
            (execute-prompt prompt) 
            (execute-rag-prompt prompt)))))))

(nvim.set_keymap :v :<leader>ai ":lua require('nano-copilot').copilot()<CR>" {})

;; I need a function that adds strings in python
;; My Docker Image should package a Node app based on a package.json file

;; ----------------

(comment
  (lsps.list)
  (dockerai.into-buffer "Summarize this project")
  (dockerai.into-buffer "Write a compose file with php and mysql server"))

;; Now integrate Docker AI
(defn dockerCopilot []
  (let [prompts (dockerai.questions)]
    (vim.ui.select
      prompts
      {:prompt "Select a prompt:"
       :format (fn [item] (item:gsub "_" " "))}
      (fn [selected _]
        (if (= selected "Custom Question")
          (let [q (vim.fn.input "Custom Question: ")]
            (dockerai.into-buffer q))
          (dockerai.into-buffer selected))))))

(nvim.set_keymap :n :<leader>ai ":lua require('nano-copilot').dockerCopilot()<CR>" {})

