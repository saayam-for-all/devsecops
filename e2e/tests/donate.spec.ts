import { test, expect } from '@playwright/test';

test('Donate page loads successfully', async ({ page }) => {
  await page.goto('https://saayamforall.org/donate');
  await expect(page.locator('h1')).toContainText(/Make a donation/i);
});
