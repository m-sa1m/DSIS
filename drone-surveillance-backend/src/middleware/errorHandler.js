function errorHandler(err, req, res, _next) {
  console.error(err.stack || err.message);
  const status = err.status || 500;
  res.status(status).json({
    success: false,
    message: err.message || 'Internal server error',
  });
}

module.exports = errorHandler;
