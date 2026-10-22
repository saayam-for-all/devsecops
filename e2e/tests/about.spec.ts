import { test, expect } from '@playwright/test';

test('About page loads successfully', async ({ page }) => {
  await page.goto('https://saayamforall.org/about');
  await expect(page).toHaveTitle(/Saayam For All/i);
});
