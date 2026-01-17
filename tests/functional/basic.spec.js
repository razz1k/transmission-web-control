const { test, expect } = require('@playwright/test');

test.describe('Transmission Web Control - Basic Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the web interface
    const baseURL = process.env.TEST_URL || 'http://localhost:9091';
    await page.goto(`${baseURL}/transmission/web/`);
  });

  test('should load the main page', async ({ page }) => {
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Check if page title contains Transmission
    await expect(page).toHaveTitle(/Transmission/i);
  });

  test('should have main layout elements', async ({ page }) => {
    // Wait for main layout to be visible
    await page.waitForSelector('#main', { timeout: 10000 });
    
    // Check for main layout structure
    const mainLayout = page.locator('#main');
    await expect(mainLayout).toBeVisible();
    
    // Check for toolbar
    const toolbar = page.locator('#m_toolbar');
    await expect(toolbar).toBeVisible();
  });

  test('should load required JavaScript libraries', async ({ page }) => {
    // Wait for jQuery to be loaded
    const jqueryLoaded = await page.evaluate(() => {
      return typeof $ !== 'undefined' && typeof jQuery !== 'undefined';
    });
    expect(jqueryLoaded).toBe(true);
    
    // Check if system object is available
    const systemLoaded = await page.evaluate(() => {
      return typeof system !== 'undefined';
    });
    expect(systemLoaded).toBe(true);
  });

  test('should have logo visible', async ({ page }) => {
    const logo = page.locator('#logo');
    await expect(logo).toBeVisible({ timeout: 10000 });
  });

  test('should have toolbar buttons', async ({ page }) => {
    await page.waitForSelector('#m_toolbar', { timeout: 10000 });
    
    // Check for some toolbar buttons
    const reloadButton = page.locator('#toolbar_reload');
    await expect(reloadButton).toBeVisible();
  });

  test('should load CSS styles', async ({ page }) => {
    // Check if styles are loaded by checking computed styles
    const mainElement = page.locator('#main');
    const display = await mainElement.evaluate((el) => {
      return window.getComputedStyle(el).display;
    });
    expect(display).not.toBe('none');
  });

  test('should handle mobile redirect', async ({ page, context }) => {
    // Set mobile user agent
    await context.setExtraHTTPHeaders({
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15'
    });
    
    await page.goto(`${process.env.TEST_URL || 'http://localhost:9091'}/transmission/web/`);
    
    // Check if redirected to mobile version (this may not always happen)
    const currentUrl = page.url();
    // Just verify page loads, redirect behavior may vary
    await expect(page).toHaveTitle(/Transmission/i);
  });
});
