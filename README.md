# Finance Tracker

A polished, premium personal finance tracker built with Flutter.

## Features
- Natural Language & Voice Input for expense tracking (Powered by OpenAI).
- Modern Dark Fintech UI inspired by top-tier banking apps.
- Monthly Budget Progress indicators.
- Donut chart analytics for expense breakdown.
- Local SQLite storage.
- Export to CSV.

## Tech Stack
- Frontend: Flutter & Dart
- State Management: Riverpod
- Database: sqflite
- Analytics: fl_chart
- Voice: speech_to_text
- LLM API: OpenAI (GPT-3.5-Turbo) via http

## Architecture
The app follows a clean architecture pattern:
- **Models:** Data structures (`TransactionModel`, `BudgetModel`).
- **DB Layer:** `DatabaseHelper` handles SQLite CRUD operations.
- **Services:** External integrations (`LlmService`, `VoiceService`).
- **Repositories:** Abstract data access (`TransactionRepository`, `BudgetRepository`).
- **Providers:** Riverpod providers (`TransactionNotifier`, `BudgetNotifier`) manage app state.
- **UI:** Flutter screens and widgets reacting to state changes.

## Setup Instructions
1. Clone the repository.
2. Run `flutter pub get`.
3. Create a `.env` file in the root directory based on `.env.example`:
   `OPENAI_API_KEY=your_key_here`
4. Run the app: `flutter run`.

## Dependencies
- flutter_riverpod
- sqflite
- path_provider
- fl_chart
- speech_to_text
- flutter_dotenv
- http
- intl
- uuid
- path
