local ok, dap = pcall(require, 'dap')
if not ok then
    return
end

dap.configurations.java = {
    {
        name = 'Attach to IronProxy Router',
        type = 'java',
        request = 'attach',
        hostName = 'localhost',
        port = 5050,
        sourcePaths = function()
            local root = vim.fn.getcwd()
            return {
                root .. '/src/IronProxyEngineCore/main/java',
                root .. '/src/IronProxyEngineBase/main/java',
                root .. '/src/IronProxyEngineMysql/main/java',
                root .. '/src/IronProxyEngineMysqlService/main/java',
                root .. '/src/IronProxyEnginePostgres/main/java',
                root .. '/src/IronProxyEnginePostgresService/main/java',
            }
        end,
    },
}
