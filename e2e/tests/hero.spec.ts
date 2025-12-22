import { test, expect } from '@playwright/test';

test('Hero section loads correctly', async ({ page }) => {
  await page.goto('https://saayamforall.org/');
  const heroTitle = page.locator('h1').first();
  await expect(heroTitle).toContainText(/Need help/i);
});
