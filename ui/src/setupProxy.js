const { createProxyMiddleware } = require('http-proxy-middleware');

// replace 'target' with your urbit instance

module.exports = function(app) {
  app.use(
    [
      /\/apps\/webterm|\/cliff|\/~\/channel|\/~_~\/slog|\/~\/scry\/docs\/usr|\/session\.js/,
    ],
    createProxyMiddleware({
      target: 'http://localhost:8085',
      changeOrigin: true,
    })
  );
};
