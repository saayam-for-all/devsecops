import { test, expect, Page } from '@playwright/test';

async function ensureDesktop(page: Page) {
  // force desktop so the top navbar (not hamburger) is present
  await page.setViewportSize({ width: 1440, height: 900 });
}

/** open the About Us dropdown (works whether it's a link or a button) */
async function openAboutDropdown(page: Page) {
  const aboutBtn = page.getByRole('button', { name: /about us/i }).first();
  const aboutLink = page.getByRole('link', { name: /about us/i }).first();
  const trigger = (await aboutBtn.count()) ? aboutBtn : aboutLink;
  await trigger.scrollIntoViewIfNeeded();
  await trigger.click({ timeout: 15000 });
}

test('home page shows hero text', async ({ page, baseURL }) => {
  await ensureDesktop(page);
  await page.goto(baseURL!);
  await expect(page.getByText(/Need help\?\s*Here to help\?/i)).toBeVisible();
});

test('About Us dropdown → Our Team & Our Mission', async ({ page, baseURL }) => {
  await ensureDesktop(page);
  await page.goto(baseURL!);

  // Our Team
  await openAboutDropdown(page);
  await page.getByRole('menuitem', { name: /our team/i }).first().click({ timeout: 15000 });
  await expect(page).toHaveURL(/\/our-team/i, { timeout: 15000 });
  await expect(page.getByRole('heading', { name: /our team/i })).toBeVisible();

  // Our Mission
  await page.goto(baseURL!);
  await openAboutDropdown(page);
  await page.getByRole('menuitem', { name: /our mission/i }).first().click({ timeout: 15000 });
  await expect(page).toHaveURL(/\/our-mission/i, { timeout: 15000 });
  await expect(page.getByRole('heading', { name: /our mission/i })).toBeVisible();
});

test('Contact Us navigates to contact page', async ({ page, baseURL }) => {
  await ensureDesktop(page);
  await page.goto(baseURL!);
  await page.getByRole('link', { name: /contact us/i }).first().click();
  await expect(page).toHaveURL(/\/contact/i, { timeout: 15000 });
  await expect(page.getByRole('heading', { name: /contact/i })).toBeVisible();
});

test('Donate navigates to internal donate page', async ({ page, baseURL }) => {
  await ensureDesktop(page);
  await page.goto(baseURL!);

  // On this site Donate is a button that routes to /donate (same origin)
  const donateBtn = page.getByRole('button', { name: /donate/i }).first();
  await donateBtn.click({ timeout: 15000 });

  await expect(page).toHaveURL(/\/donate/i, { timeout: 15000 });
  await expect(page.getByRole('heading', { name: /make a donation/i })).toBeVisible();
});
