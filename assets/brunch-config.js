exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: {
        "js/app.js": /^(?!admin)/,
        "js/admin/admin.js": /^js\/admin/,
      },

      // To use a separate vendor.js bundle, specify two files path
      // http://brunch.io/docs/config#-files-
      // joinTo: {
      //   "js/app.js": /^js/,
      //   "js/vendor.js": /^(?!js)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      order: {
        before: [
          "js/admin/vendor/jquery.min.js",
          "js/admin/vendor/popper.min.js",
          "js/admin/vendor/bootstrap.min.js",
          "js/admin/vendor/perfect-scrollbar.jquery.min.js",
          "js/admin/vendor/moment.min.js",
          "js/admin/vendor/sweetalert2.min.js",
          "js/admin/vendor/jquery.validate.min.js",
          "js/admin/vendor/jquery.bootstrap-wizard.js",
          "js/admin/vendor/bootstrap-selectpicker.js",
          "js/admin/vendor/bootstrap-switch.js",
          "js/admin/vendor/bootstrap-datetimepicker.js",
          "js/admin/vendor/jquery.dataTables.min.js",
          "js/admin/vendor/bootstrap-tagsinput.js",
          "js/admin/vendor/jasny-bootstrap.min.js",
          "js/admin/vendor/jquery-jvectormap.js",
          "js/admin/vendor/nouislider.min.js",
          "js/admin/vendor/chartjs.min.js",
          "js/admin/vendor/bootstrap-notify.js",
          "js/admin/vendor/now-ui-dashboard.js",
          "js/admin/schedule.js"
        ]
      }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": /^(?!admin)/,
        "css/admin/admin.css": /^css\/admin/
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: ["static", "css", "js", "vendor"],
    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    }
  },

  optimize: false,

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"],
      "js/admin/admin.js": ["js/admin/admin"]
    }
  },

  npm: {
    enabled: true
  }
};
