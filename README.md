# PetTracker

A simple, modern iOS app for managing and tracking your duties as a pet owner. Currently supports dogs and cats.

## Features

- **Dashboard** - See today's tasks, overdue items, and upcoming duties at a glance
- **Pet Profiles** - Add dogs and cats with breed, age, weight, and notes
- **Duty Tracking** - Track feeding, walking, litter box, grooming, vet visits, medications, and more
- **Recurring Tasks** - Set duties to repeat daily, weekly, monthly, etc.
- **Smart Categories** - Duty types adapt to your pet (walks for dogs, litter box for cats)
- **Completion Tracking** - Mark duties as done with a single tap

## Requirements

- macOS with Xcode 15+
- iOS 17.0+ deployment target

## Setup

1. Clone this repository
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen):
   ```bash
   brew install xcodegen
   ```
3. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```
4. Open `PetTracker.xcodeproj` in Xcode
5. Select your target device/simulator and press Run

## Architecture

- **SwiftUI** - Modern declarative UI framework
- **MVVM** - Clean separation of models, views, and data logic
- **UserDefaults** - Lightweight local persistence (no server needed)

## Project Structure

```
PetTracker/
├── PetTrackerApp.swift          # App entry point
├── Models/
│   ├── Pet.swift                # Pet data model (Dog, Cat)
│   └── PetDuty.swift            # Duty/task data model
├── Services/
│   └── DataStore.swift          # Data persistence & business logic
├── Views/
│   ├── ContentView.swift        # Tab navigation
│   ├── Dashboard/
│   │   └── DashboardView.swift  # Today's overview
│   ├── Pets/
│   │   ├── PetListView.swift    # Pet list
│   │   ├── AddEditPetView.swift # Add/edit pet form
│   │   └── PetDetailView.swift  # Pet profile & duties
│   └── Duties/
│       ├── DutyRowView.swift    # Duty list item
│       └── AddEditDutyView.swift # Add/edit duty form
└── Assets.xcassets/             # App icons & colors
```
