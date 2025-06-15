const { navigateToRoute } = require('../src/utils/navigation');

describe('Navigation Logic', () => {
  test('should navigate to employee dashboard for non-admin user', () => {
    const route = '/';
    const isAdmin = false;
    const targetRoute = navigateToRoute(route, isAdmin);
    expect(targetRoute).toBe('/employee_dashboard');
  });

  test('should navigate to specified route for admin user', () => {
    const route = '/analytics';
    const isAdmin = true;
    const targetRoute = navigateToRoute(route, isAdmin);
    expect(targetRoute).toBe('/analytics');
  });

  test('should navigate to specified route for non-admin user', () => {
    const route = '/profile';
    const isAdmin = false;
    const targetRoute = navigateToRoute(route, isAdmin);
    expect(targetRoute).toBe('/profile');
  });
});
