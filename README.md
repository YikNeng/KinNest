# KinNest - A Smart Elderly Care Application

KinNest is a mobile application designed to assist the elderly in maintaining a healthy and organized lifestyle. Built with **Flutter** and **Firebase**, it utilizes Machine Learning and OCR technology to provide personalized care features.

This project was developed as a Final Year Project for the Bachelor of Software Engineering program at Universiti Putra Malaysia (UPM).

## 📱 Key Features

* **AI-Powered Exercise Routines:** Generates personalized exercise plans for elderly users based on their health status using a Machine Learning model.
* **Smart Appointment Scanning (OCR):** Users can scan physical medical appointment cards to automatically extract dates, times, and locations using the Google Cloud Vision API.
* **Medicine & Activity Reminders:** Custom alerts to ensure medication compliance and daily routine adherence.
* **Wellness Module:** Includes relaxing music and wellness tools to support mental health.

## 🛠 Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase (Auth, Firestore)
* **AI/ML:** Google Cloud Vision API (OCR), Gemini API (Exercise Generation)

## 🚀 Getting Started

To run this project locally, follow these steps.

### Prerequisites
* Flutter SDK installed
* Git installed
* An Android Emulator or Physical Device

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/YikNeng/KinNest.git
    cd KinNest
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Configuration**
    This project relies on API keys that are not included in the repository for security reasons. You must set them up locally.
    
    1.  Create a file named `.env` in the root directory of the project.
    2.  Add your API keys in the following format:
        ```env
        OCR_KEY=your_actual_api_key_here
        YOUTUBE_API_KEY=your_actual_api_key_here
        GEMINI_KEY=your_actual_api_key_here
        ```
    3.  Ensure `google-services.json` is placed in `android/app/` (for Firebase connection).

4.  **Run the App**
    ```bash
    flutter run
    ```
