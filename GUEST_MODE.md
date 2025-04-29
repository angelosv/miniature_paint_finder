# Guest Mode Implementation

This document explains how guest mode works in the Miniature Paint Finder app.

## Overview

Guest mode allows users to access limited functionality without creating an account or signing in. This feature was implemented to satisfy Apple's App Store requirements to allow basic app functionality without requiring authentication.

## Features Available to Guest Users

Guest users can access the following features:
- Browse the paint library
- Search for paints by name, brand, category, or color
- Use the barcode scanner to look up paint information
- Use the color picker tool to find matching paints

## Features Requiring Authentication

The following features require the user to sign in:
- Add paints to inventory
- Add paints to wishlist
- Create and manage palettes
- Access personal settings and user profile

## Implementation Details

### Authentication Service

The `AuthService` class was extended to support guest users:
- Added `isGuestUser` property to check if the current user is a guest
- Added `continueAsGuest()` method to create a temporary guest user object
- Guest users have a unique ID but don't have actual Firebase authentication

### Auth Screen

A "Continue as Guest" button was added to the welcome screen to allow users to enter the app without signing in.

### Guest Service

The `GuestService` utility class provides:
- Methods to check if a feature is accessible to guest users
- UI components for wrapping screens with guest mode banners
- Authentication prompt dialogs for restricted features

### Restricted Feature Access

When a guest user attempts to access a restricted feature:
1. A dialog appears explaining that authentication is required
2. The user can either cancel or navigate to the sign-in screen

### Navigation Drawer

The navigation drawer displays:
- A "Guest Mode" indicator for guest users
- Lock icons next to menu items that require authentication

## Adding New Features

When adding new features to the app:
1. Determine if the feature should be accessible to guest users
2. Use `AuthUtils.checkFeatureAccess()` to verify access before executing restricted actions
3. Update the `guestAccessibleFeatures` list in `GuestService` if needed

## Testing Guest Mode

To test guest mode:
1. Launch the app and tap "Continue as Guest"
2. Verify that all guest-accessible features work correctly
3. Attempt to access restricted features and confirm that authentication prompts appear
4. Sign in from a restricted feature prompt and verify it navigates to the auth screen
5. After signing in, verify that all features are now accessible 