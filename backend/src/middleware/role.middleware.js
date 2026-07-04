const roleMiddleware = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        message: "Önce giriş yapmalısın.",
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        message: "Bu işlem için yetkin yok.",
      });
    }

    next();
  };
};

module.exports = roleMiddleware;