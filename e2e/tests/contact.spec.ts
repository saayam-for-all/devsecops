import { test, expect } from '@playwright/test';

test('Contact page loads successfully', async ({ page }) => {
  await page.goto('https://saayamforall.org/contact');
  await expect(page).toHaveTitle(/Saayam For All/i);
});
