return {
  {
    name = 'amazonq',
    url = 'https://github.com/awslabs/amazonq.nvim.git',
    opts = {
      ssoStartUrl = 'https://amzn.awsapps.com/start',  -- Authenticate with Amazon Q Free Tier
    },
    enabled = function()
            return not vim.g.g_disable_amazon_plugins
    end
  },
}
