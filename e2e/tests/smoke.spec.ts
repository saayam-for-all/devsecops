import { test, expect, Page } from '@playwright/test';

// Force desktop so the full navbar is present (no hamburger)
async function ensureDesktop(page: Page) {
  await page.setViewportSize({ width: 1440, height: 900 });
}

async function openDropdown(page: Page, labelRe: RegExp) {
  // The trigger can be a button or a link (MUI menu)
  const btn  = page.getByRole('button', { name: labelRe }).first();
  const link = page.getByRole('link',   { name: labelRe }).first();
  const trigger = (await btn.count()) ? btn : link;
  await trigger.scrollIntoViewIfNeeded();
  await trigger.click();
  // Wait for the menu to render
  await expect(page.getByRole('menu')).toBeVisible({ timeout: 5000 });
}

test('home page shows hero text', async ({ page, baseURL }) => {
  await ensureDesktop(page);
  await page.goto(baseURL!);
  await expect(page.getByText(/Need help\?\s*Here to help\?/i)).toBeVisible();
});

/* -------------------- ABOUT US -------------------- */
test('About Us → Our Team', async ({ page, baseURL }) => {
  await ensureDesktop(page);
  await page.goto(baseURL!);

  await openDropdown(page, /about us/i);
  await page.getByRole('menuitem', { name: /our team/i }).first().click();

  await expect(page).toHaveURL(/\/our-team/i, { timeout: 15000 });
  // Actual heading on the page
  await expect(page.getByRole('heading', { name: /Meet the Board of Directors/i }))
    .toBeVisible();
});

test('About Us → Our Mission', async ({ page, baseURL }) => {
  await ensureDesktop(page);
  await page.goto(baseURL!);

  await openDropdown(page, /about us/i);
  await page.getByRole('menuitem', { name: /our mission/i }).first().click();

  await expect(page).toHaveURL(/\/our-mission/i, { timeout: 15000 });
  await expect(page.getByRole('heading', { name: /Our Mission/i })).toBeVisible();
});

/* --------------- VOLUNTEER SERVICES --------------- */
test('Volunteer Services → How We Operate', async ({ page, baseURL }) => {
  await ensureDesktop(page);
  await page.goto(baseURL!);

  await openDropdown(page, /volunteer services/i);
  await page.getByRole('menuitem', { name: /how we operate/i }).first().click();

  // If there is a dedicated route, assert it here; otherwise just assert heading.
  await expect(page.getByRole('heading', { name: /How We Operate/i }))
    .toBeVisible({ timeout: 15000 });
});

test('Volunteer Services → Our Collaborators', async ({ page, baseURL }) => {
  await ensureDesktop(page);
  await page.goto(baseURL!);

  await openDropdown(page, /volunteer services/i);
  await page.getByRole('menuitem', { name: /our collaborators/i }).first().click();

  await expect(page.getByRole('heading', { name: /Our Collaborators/i }))
    .toBeVisible({ timeout: 15000 });
});

/* ---------------- CONTACT & DONATE ---------------- */
test('Contact Us navigates to contact page', async ({ page, baseURL }) => {
  await ensureDesktop(page);
  await page.goto(baseURL!);

  await page.getByRole('link', { name: /contact us/i }).first().click();

  await expect(page).toHaveURL(/\/contact/i, { timeout: 15000 });
  await expect(page.getByRole('heading', { name: /Contact Us/i })).toBeVisible();
});

test('Donate navigates to internal donate page', async ({ page, baseURL }) => {
  await ensureDesktop(page);
  await page.goto(baseURL!);

  await page.getByRole('button', { name: /donate/i }).first().click();

  await expect(page).toHaveURL(/\/donate/i, { timeout: 15000 });
  await expect(page.getByRole('heading', { name: /Make a donation/i })).toBeVisible();
});
