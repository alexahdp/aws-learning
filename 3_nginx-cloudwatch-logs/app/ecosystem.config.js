module.exports = {
  apps: [
    {
      name: 'appexample',
      script: './main.js',
      exec_mode: 'cluster',
      instances: 2,
      combine_logs: true,
      merge_logs: true,
      out_file: './logs/out.log',
      error_file: './logs/error.log',
    },
  ],
};