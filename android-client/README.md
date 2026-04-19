# Android Client (Kotlin + XML)

MVVM Android client for constituency -> candidates -> poll flow.

## Features Included

- Home top section with `HITS` title + `clg_logo`
- Scrollable constituency list with pull-to-refresh
- Candidate list screen with fade-in cards
- Poll screen (local vote storage) with animated progress bars
- Lottie loading animation in API-loading states
- Retrofit + Flow + ViewModel architecture

## Required Gradle Dependencies (app)

```kotlin
implementation("androidx.core:core-ktx:1.15.0")
implementation("androidx.appcompat:appcompat:1.7.0")
implementation("com.google.android.material:material:1.12.0")
implementation("androidx.constraintlayout:constraintlayout:2.2.0")
implementation("androidx.fragment:fragment-ktx:1.8.6")
implementation("androidx.navigation:navigation-fragment-ktx:2.8.8")
implementation("androidx.navigation:navigation-ui-ktx:2.8.8")
implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
implementation("androidx.recyclerview:recyclerview:1.4.0")
implementation("androidx.swiperefreshlayout:swiperefreshlayout:1.1.0")
implementation("com.squareup.retrofit2:retrofit:2.11.0")
implementation("com.squareup.retrofit2:converter-gson:2.11.0")
implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
implementation("com.airbnb.android:lottie:6.5.0")
```

## Setup

1. Put your college logo at `app/src/main/res/drawable/clg_logo.png`.
2. Put your Lottie JSON at `app/src/main/res/raw/loading_animation.json`.
3. Set backend URL in `ApiModule.kt`.

