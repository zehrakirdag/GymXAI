# GymXAI

GymXAI is an AI-supported smart gym management and client tracking system developed as a bachelor's final year project.

The project aims to digitalize the main operational processes of gyms by bringing gym members, trainers and administrators together in a single mobile platform. It supports client progress tracking, workout program management, trainer working hours, appointment requests, gym occupancy tracking and AI-assisted workout program recommendations.

## Project Overview

In traditional gym management, client measurements, workout programs, appointment requests and trainer-client communication are often managed through paper records, messaging applications or disconnected tools. This can cause data loss, communication problems and difficulty in tracking client progress.

GymXAI was developed to solve these problems with a role-based mobile system. The application provides separate workflows for Admin, Trainer and Client users. Each role has access to different features according to its responsibilities.

## User Roles

### Admin
- Manages users in the system
- Controls trainer and client accounts
- Monitors general system operations
- Supports overall gym management processes

### Trainer
- Views assigned clients
- Creates and manages workout programs
- Manages working hours
- Reviews appointment and special lesson requests
- Evaluates AI-generated workout recommendations before approval

### Client
- Views personal profile and fitness goals
- Tracks body measurements and BMI values
- Views assigned workout programs
- Completes workout exercises
- Sends appointment or special lesson requests
- Uses QR-based gym check-in/check-out
- Receives notifications and progress updates

## Key Features

- Role-based authentication and navigation
- Admin, Trainer and Client panels
- Client measurement and BMI tracking
- Workout program creation and tracking
- Trainer working hours management
- Appointment and special lesson request flow
- Notification system
- QR-based gym check-in/check-out
- Real-time gym occupancy tracking
- AI-supported workout program recommendation
- Trainer approval process for AI recommendations
- Modular backend architecture
- Relational database design

## Technologies Used

### Mobile Application
- Flutter
- Dart

### Backend
- Node.js
- Express.js
- RESTful API

### Database and ORM
- PostgreSQL
- Prisma ORM

### Artificial Intelligence Module
- Python
- pandas
- NumPy
- scikit-learn
- RandomForestClassifier

### Other Tools
- JWT Authentication
- QR Code-based flow
- Git / GitHub

## AI Recommendation Module

GymXAI includes an AI-supported workout recommendation module. The model analyzes client-related data and suggests a suitable workout program type.

The model uses features such as:

- Age
- Gender
- BMI
- Fitness goal
- Activity level
- Health issue status
- Injury status
- Weight change
- Target weight difference
- Program progress

The AI module does not directly assign the workout program to the client. Instead, the prediction is sent to the trainer for review. The trainer can approve, edit or reject the recommendation. This approach combines automation with human expertise and provides a safer decision-support mechanism.

## AI Model Performance

The AI model was trained using a dataset prepared for the project. A Random Forest classification algorithm was used for program type prediction.

The model achieved approximately:

- 96.34% accuracy in 5-fold cross-validation
- 95.73% accuracy on the test set

These results show that the model can successfully learn patterns from the prepared dataset. However, in real-world usage, the model should be improved with larger and more diverse real user data.

## System Architecture

GymXAI follows a layered architecture:

- The Flutter mobile application provides the user interface.
- The Node.js / Express.js backend handles business logic and API requests.
- Prisma ORM manages database operations.
- PostgreSQL stores user, trainer, client, workout, measurement, appointment and notification data.
- The Python AI module produces workout program recommendations.
- The trainer approval flow controls AI-generated outputs before they are applied.

This structure makes the system modular, maintainable and extendable.

## Project Purpose

The main purpose of GymXAI is to reduce manual tracking in gyms, improve trainer-client communication and support data-driven fitness management.

The system helps gyms manage their daily operations more efficiently while allowing clients to track their fitness progress in a more organized way.

## Future Improvements

- Cloud deployment
- Docker support
- Advanced analytics dashboard
- Wearable device integration
- Improved AI recommendation model
- Explainable AI support
- Multi-language support
- Web-based admin dashboard
- More detailed performance reporting

## About This Project

This project was developed as a bachelor's final year project in Computer Engineering. It combines mobile application development, backend development, database design and artificial intelligence into a single real-world software system.

---

# Türkçe Açıklama

GymXAI, yapay zekâ destekli akıllı spor salonu yönetimi ve danışan takip sistemi olarak geliştirilmiş bir bitirme projesidir.

Projenin amacı; spor salonlarında danışan takibi, ölçüm kayıtları, antrenman programları, antrenör çalışma saatleri, özel ders talepleri, salon yoğunluğu ve yapay zekâ destekli program önerisi gibi süreçleri tek bir mobil platform altında toplamaktır.

## Proje Özeti

Geleneksel spor salonu yönetiminde danışan ölçümleri, programlar, randevular ve antrenör-danışan iletişimi çoğu zaman kâğıt, mesajlaşma uygulamaları veya dağınık dijital araçlar üzerinden yürütülür. Bu durum veri kaybına, iletişim sorunlarına ve danışan gelişiminin düzenli takip edilememesine yol açabilir.

GymXAI bu problemi çözmek için rol bazlı bir mobil sistem olarak tasarlanmıştır. Sistemde Admin, Antrenör ve Danışan olmak üzere üç temel kullanıcı rolü vardır.

## Kullanıcı Rolleri

### Admin
- Kullanıcıları yönetir
- Antrenör ve danışan hesaplarını kontrol eder
- Sistemin genel yönetimini sağlar

### Antrenör
- Danışanlarını görüntüler
- Antrenman programı oluşturur
- Çalışma saatlerini düzenler
- Özel ders ve randevu taleplerini yönetir
- Yapay zekâ tarafından önerilen programları onaylar, düzenler veya reddeder

### Danışan
- Profil ve hedef bilgilerini görüntüler
- Ölçüm ve BMI takibi yapar
- Antrenman programını görüntüler
- Egzersiz tamamlama işlemlerini gerçekleştirir
- Özel ders talebi oluşturur
- QR kod ile spor salonu giriş/çıkış işlemi yapar
- Bildirimleri takip eder

## Temel Özellikler

- Rol bazlı giriş sistemi
- Admin, Antrenör ve Danışan panelleri
- Ölçüm ve BMI takibi
- Antrenman programı yönetimi
- Antrenör çalışma saatleri
- Özel ders ve randevu talep akışı
- Bildirim sistemi
- QR kod tabanlı giriş/çıkış sistemi
- Salon yoğunluğu takibi
- Yapay zekâ destekli program önerisi
- Antrenör onay mekanizması
- Modüler backend yapısı
- İlişkisel veritabanı tasarımı

## Kullanılan Teknolojiler

- Flutter
- Dart
- Node.js
- Express.js
- Prisma ORM
- PostgreSQL
- Python
- scikit-learn
- Random Forest
- JWT Authentication
- RESTful API

## Yapay Zekâ Modülü

GymXAI içerisindeki yapay zekâ modülü, danışan bilgilerini analiz ederek uygun antrenman programı türü önerir.

Modelin kullandığı bazı veriler:

- Yaş
- Cinsiyet
- BMI
- Hedef
- Aktivite düzeyi
- Sağlık durumu
- Sakatlık bilgisi
- Kilo değişimi
- Hedef kiloya uzaklık
- Program ilerlemesi

Yapay zekâ çıktısı doğrudan danışana atanmaz. Önce antrenör ekranına gönderilir. Antrenör öneriyi onaylayabilir, düzenleyebilir veya reddedebilir. Böylece sistem, otomasyonu insan uzmanlığıyla birleştiren daha güvenli bir karar destek yapısı sunar.

## Projenin Amacı

GymXAI, spor salonlarında manuel takip süreçlerini azaltmak, antrenör-danışan iletişimini dijitalleştirmek, danışan gelişimini veri odaklı takip etmek ve spor salonu yönetimini daha düzenli hale getirmek amacıyla geliştirilmiştir.

## Gelecek Geliştirmeler

- Bulut ortamına dağıtım
- Docker desteği
- Gelişmiş analiz paneli
- Giyilebilir cihaz entegrasyonu
- Daha gelişmiş yapay zekâ modeli
- Açıklanabilir yapay zekâ desteği
- Çoklu dil desteği
- Web tabanlı admin paneli
