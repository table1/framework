export const buildGitPanelModel = ({ useGit, gitHooks, git, author } = {}) => {
  const hooks = gitHooks || git?.hooks || {}
  return {
    initialize: useGit !== false && (git?.initialize !== false),
    user_name: git?.user_name || '',
    user_email: git?.user_email || '',
    hooks: {
      ai_sync: hooks.ai_sync || false,
      data_security: hooks.data_security || false,
      check_sensitive_dirs: hooks.check_sensitive_dirs || false
    }
  }
}

/**
 * Apply a Git panel model back onto state objects.
 * - gitTarget: object holding git fields (initialize, user_name, user_email, hooks)
 * - gitHooksTarget: object for defaults.git_hooks (optional)
 * - setUseGit: function to set defaults.use_git (optional)
 */
export const applyGitPanelModel = ({ gitTarget, gitHooksTarget, setUseGit } = {}, model = {}) => {
  if (typeof setUseGit === 'function') {
    setUseGit(model.initialize)
  }

  if (gitTarget) {
    gitTarget.initialize = model.initialize
    gitTarget.user_name = model.user_name
    gitTarget.user_email = model.user_email
    gitTarget.hooks = {
      ai_sync: model.hooks?.ai_sync || false,
      data_security: model.hooks?.data_security || false,
      check_sensitive_dirs: model.hooks?.check_sensitive_dirs || false
    }
  }

  if (gitHooksTarget) {
    gitHooksTarget.ai_sync = model.hooks?.ai_sync || false
    gitHooksTarget.data_security = model.hooks?.data_security || false
    gitHooksTarget.check_sensitive_dirs = model.hooks?.check_sensitive_dirs || false
  }
}
