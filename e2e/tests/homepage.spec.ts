import { test, expect } from '@playwright/test';

test('homepage has title and links', async ({ page }) => {
  await page.goto('https://example.com');
  await expect(page).toHaveTitle(/Example Domain/);
  const link = page.locator('a');
  await expect(link).toHaveAttribute('href', 'https://www.iana.org/domains/example');
});
