function navigateToRoute(route, isAdmin) {
  return route === '/' && !isAdmin ? '/employee_dashboard' : route;
}

module.exports = { navigateToRoute };
