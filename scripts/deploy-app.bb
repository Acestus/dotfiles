#!/usr/bin/env bb

(require '[babashka.fs :as fs]
         '[clojure.java.shell :refer [sh]]
         '[clojure.string :as str])

;; ── Helpers ──────────────────────────────────────────────────────────────────

(defn die [message]
  (binding [*out* *err*]
    (println (str "❌ " message)))
  (System/exit 1))

(defn run! [& args]
  (let [result (apply sh args)]
    (when-not (zero? (:exit result))
      (binding [*out* *err*]
        (println (str "❌ Command failed: " (str/join " " args)))
        (when-let [err (:err result)]
          (println (str/trim err)))
        (when (not (str/blank? (:out result)))
          (println (str/trim (:out result)))))
      (System/exit (:exit result)))
    result))

(defn run-result! [& args]
  (apply sh args))

(defn az! [& args]
  (apply run! "az" args))

(defn az-result [& args]
  (apply run-result! "az" args))

(def green "\u001b[32m")
(def red "\u001b[31m")
(def yellow "\u001b[33m")
(def blue "\u001b[34m")
(def cyan "\u001b[36m")
(def gray "\u001b[90m")
(def reset "\u001b[0m")

(defn colorize [message color]
  (str color message reset))

(defn write-color-output
  ([message]
   (write-color-output message reset))
  ([message color]
   (println (colorize message color))))

(defn shell-quote [value]
  (str "'" (str/replace (str value) "'" "'\"'\"'") "'"))

(defn run-in-dir! [dir & args]
  (let [cmd (str "cd " (shell-quote dir)
                 " && "
                 (str/join " " (map shell-quote args)))
        result (sh "bash" "-lc" cmd)]
    (when-not (zero? (:exit result))
      (binding [*out* *err*]
        (println (str "❌ Command failed in " dir ": " (str/join " " args)))
        (when-let [err (:err result)]
          (println (str/trim err)))
        (when-not (str/blank? (:out result))
          (println (str/trim (:out result)))))
      (System/exit (:exit result)))
    result))

(defn parse-args [args]
  (loop [args args opts {}]
    (if (empty? args)
      opts
      (let [[arg next-arg & rest] args]
        (cond
          (#{"-h" "--help"} arg)
          (assoc opts :help true)

          (#{"--env" "--stack" "--resource-group" "--function-app"} arg)
          (if (nil? next-arg)
            (die (str "Missing value for " arg))
            (let [key (keyword (subs arg 2))]
              (when (and (= key :stack) (not= next-arg "blog"))
                (die "--stack must be blog"))
              (recur (vec rest) (assoc opts key next-arg))))

          (= "--skip-build" arg)
          (recur (vec (if (nil? next-arg) rest (cons next-arg rest)))
                 (assoc opts :skip-build true))

          (= "--skip-validation" arg)
          (recur (vec (if (nil? next-arg) rest (cons next-arg rest)))
                 (assoc opts :skip-validation true))

          :else (die (str "Unknown argument: " arg)))))))

(defn usage []
  (println "Usage: bb deploy-app.bb --stack blog --env dev|prd [--resource-group NAME] [--function-app NAME] [--skip-build] [--skip-validation]")
  (println "")
  (println "Builds the blog and deploys to Azure Functions (Flex Consumption).")
  (println "")
  (println "Steps: prep → test → uber → zip → config-zip deploy")
  (println "")
  (println "Options:")
  (println "  --stack blog         Stack selector (blog only)")
  (println "  --env dev|prd         Target environment (required)")
  (println "  --resource-group      Override the resource group from env config")
  (println "  --function-app        Override the function app name from env config")
  (println "  --skip-build          Skip prep/test/build, deploy existing jar")
  (println "  --skip-validation     Skip function app existence validation")
  (println "  -h, --help            Show this help"))

;; ── Config ───────────────────────────────────────────────────────────────────

(def env-config
  {"dev" {:function-app "func-blog-dev-usw2-001"
          :resource-group "rg-blog-dev"}
   "prd" {:function-app "func-blog-prd-usw2-001"
          :resource-group "rg-blog-prd"}})

(defn resolve-config [env opts]
  (let [config (or (env-config env) (die (str "Unknown env: " env)))]
    {:env env
     :stack (or (:stack opts) "blog")
     :skip-build (:skip-build opts)
     :skip-validation (:skip-validation opts)
     :function-app (or (:function-app opts) (:function-app config))
     :resource-group (or (:resource-group opts) (:resource-group config))}))

(defn validate-function-app! [function-app resource-group]
  (let [result (az-result "functionapp" "show"
                          "--name" function-app
                          "--resource-group" resource-group
                          "-o" "json")]
    (if (zero? (:exit result))
      (do
        (write-color-output (str "✅ Function app '" function-app "' found") green)
        true)
      (do
        (write-color-output (str "❌ ERROR: Function app '" function-app "' not found in '" resource-group "'") red)
        (when-let [err (:err result)]
          (write-color-output (str/trim err) red))
        (when-not (str/blank? (:out result))
          (write-color-output (str/trim (:out result)) red))
        (System/exit 1)))))

(defn show-deployment-summary [env function-app resource-group]
  (println "")
  (write-color-output "🚀 Blog App Deployment" cyan)
  (write-color-output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" gray)
  (write-color-output (str "Environment:      " env) reset)
  (write-color-output (str "Function App:     " function-app) reset)
  (write-color-output (str "Resource Group:   " resource-group) reset)
  (write-color-output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" gray)
  (println ""))

(defn show-post-deployment-info [function-app resource-group]
  (write-color-output "Deployment Summary" green)
  (write-color-output "===================" green)
  (write-color-output (str "Function App: " function-app) green)
  (write-color-output (str "Resource Group: " resource-group) green)
  (write-color-output "Deploy Method: az functionapp deployment source config-zip" green)
  (println "")
  (write-color-output "Next steps:" blue)
  (write-color-output (str "  1. Monitor deployment logs for " function-app) blue)
  (write-color-output (str "  2. Open https://" function-app ".azurewebsites.net/") blue))

;; ── Main ─────────────────────────────────────────────────────────────────────

(let [opts (parse-args *command-line-args*)]
  (when (:help opts)
      (usage)
      (System/exit 0))

  (let [env (or (:env opts) (die "--env is required"))
        {:keys [stack skip-build skip-validation function-app resource-group]}
        (resolve-config env opts)
        repo-root (str/trim (:out (sh "git" "rev-parse" "--show-toplevel")))
        jar-path (str repo-root "/target/blog-0.1.0.jar")
        zip-path "/tmp/blog-deploy.zip"]

    (show-deployment-summary env function-app resource-group)

    ;; ── Build ────────────────────────────────────────────────────────────
    (when-not skip-build
      (write-color-output "Step 1/5: Prep content..." blue)
      (run-in-dir! repo-root "clojure" "-X:prep")
      (write-color-output "✅ Content prepped" green)
      (println "")

      (write-color-output "Step 2/5: Run tests..." blue)
      (run-in-dir! repo-root "clojure" "-M:test")
      (write-color-output "✅ Tests passed" green)
      (println "")

      (write-color-output "Step 3/5: Build uberjar..." blue)
      (run-in-dir! repo-root "clojure" "-T:build" "uber")
      (write-color-output "✅ Uberjar built" green))

    (when-not (fs/exists? jar-path)
      (die (str "Jar not found: " jar-path " (run without --skip-build)")))

    (when-not skip-validation
      (write-color-output "Validating function app..." blue)
      (validate-function-app! function-app resource-group)
      (write-color-output (str "  - Resource Group: " resource-group) blue)
      (write-color-output (str "  - Function App:   " function-app) blue))

    (println "")
    (write-color-output "Step 4/5: Create deployment archive..." blue)
    (run-in-dir! repo-root "zip" "-r" zip-path
                 "host.json"
                 "Health/function.json"
                 "Pages/function.json"
                 "target/blog-0.1.0.jar"
                 "content/"
                 "resources/")
    (write-color-output (str "✅ Archive: " zip-path " (" (-> (fs/size zip-path) (/ 1024) long) " KB)") green)

    (println "")
    (write-color-output "Step 5/5: Deploy to Azure Functions..." blue)
    (az! "functionapp" "deployment" "source" "config-zip"
         "--name" function-app
         "--resource-group" resource-group
         "--src" zip-path
         "--build-remote" "false"
         "--timeout" "120")
    (write-color-output "✅ Deployment complete" green)

    (println "")
    (show-post-deployment-info function-app resource-group)
    (write-color-output "✨ Done!" green)
    (write-color-output (str "🌐 https://" function-app ".azurewebsites.net/") cyan)))
