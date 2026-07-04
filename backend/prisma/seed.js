const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcrypt");

const prisma = new PrismaClient();
const password = "123456";

function daysAgo(days) {
  const date = new Date();
  date.setDate(date.getDate() - days);
  date.setHours(10, 0, 0, 0);
  return date;
}

async function upsertUser({ fullName, email, phone, role }) {
  const hashedPassword = await bcrypt.hash(password, 10);

  return prisma.user.upsert({
    where: { email },
    update: {
      fullName,
      phone,
      role,
      password: hashedPassword,
      isActive: true,
    },
    create: {
      fullName,
      email,
      password: hashedPassword,
      phone,
      role,
      isActive: true,
    },
  });
}

async function createTrainer({ fullName, email, phone, specialty, bio }) {
  const user = await upsertUser({
    fullName,
    email,
    phone,
    role: "TRAINER",
  });

  const trainer = await prisma.trainerProfile.upsert({
    where: { userId: user.id },
    update: {
      specialty,
      bio,
      isAvailable: true,
    },
    create: {
      userId: user.id,
      specialty,
      bio,
      isAvailable: true,
    },
  });

  await prisma.trainerWorkingHour.deleteMany({
    where: { trainerId: trainer.id },
  });

  const workingDays = [
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
  ];

  for (const dayName of workingDays) {
    await prisma.trainerWorkingHour.create({
      data: {
        trainerId: trainer.id,
        dayName,
        isAvailable: true,
        startTime: "10:00",
        endTime: "18:00",
      },
    });
  }

  await prisma.trainerWorkingHour.create({
    data: {
      trainerId: trainer.id,
      dayName: "Cumartesi",
      isAvailable: true,
      startTime: "11:00",
      endTime: "15:00",
    },
  });

  await prisma.trainerWorkingHour.create({
    data: {
      trainerId: trainer.id,
      dayName: "Pazar",
      isAvailable: false,
      startTime: null,
      endTime: null,
      note: "Haftalık izin",
    },
  });

  return { user, trainer };
}

async function cleanupClientData(clientId, userId) {
  const programs = await prisma.workoutProgram.findMany({
    where: { clientId },
    include: {
      days: {
        include: {
          exercises: true,
        },
      },
    },
  });

  const programIds = programs.map((program) => program.id);
  const dayIds = programs.flatMap((program) =>
    program.days.map((day) => day.id)
  );
  const exerciseIds = programs.flatMap((program) =>
    program.days.flatMap((day) => day.exercises.map((exercise) => exercise.id))
  );

  await prisma.notification.deleteMany({
    where: { userId },
  });

  await prisma.appointment.deleteMany({
    where: { clientId },
  });

  await prisma.exerciseSetCompletion.deleteMany({
    where: { clientId },
  });

  await prisma.exerciseCompletion.deleteMany({
    where: { clientId },
  });

  await prisma.workoutCompletion.deleteMany({
    where: { clientId },
  });

  await prisma.measurement.deleteMany({
    where: { clientId },
  });

  if (exerciseIds.length > 0) {
    await prisma.workoutExercise.deleteMany({
      where: {
        id: { in: exerciseIds },
      },
    });
  }

  if (dayIds.length > 0) {
    await prisma.workoutDay.deleteMany({
      where: {
        id: { in: dayIds },
      },
    });
  }

  if (programIds.length > 0) {
    await prisma.workoutProgram.deleteMany({
      where: {
        id: { in: programIds },
      },
    });
  }
}

async function createClient({
  fullName,
  email,
  phone,
  trainerId,
  gender,
  birthDate,
  height,
  startWeight,
  targetWeight,
  goal,
  activityLevel,
  healthNotes,
  injuryNotes,
}) {
  const user = await upsertUser({
    fullName,
    email,
    phone,
    role: "CLIENT",
  });

  const client = await prisma.clientProfile.upsert({
    where: { userId: user.id },
    update: {
      trainerId,
      gender,
      birthDate: birthDate ? new Date(birthDate) : null,
      height,
      startWeight,
      targetWeight,
      goal,
      activityLevel,
      healthNotes,
      injuryNotes,
      membershipStatus: "ACTIVE",
      membershipStart: daysAgo(90),
      membershipEnd: daysAgo(-180),
      notes: "Demo analiz verisi için oluşturuldu.",
    },
    create: {
      userId: user.id,
      trainerId,
      gender,
      birthDate: birthDate ? new Date(birthDate) : null,
      height,
      startWeight,
      targetWeight,
      goal,
      activityLevel,
      healthNotes,
      injuryNotes,
      membershipStatus: "ACTIVE",
      membershipStart: daysAgo(90),
      membershipEnd: daysAgo(-180),
      notes: "Demo analiz verisi için oluşturuldu.",
    },
  });

  await cleanupClientData(client.id, user.id);

  return { user, client };
}

async function createMeasurements(clientId, measurements) {
  for (const item of measurements) {
    await prisma.measurement.create({
      data: {
        clientId,
        weight: item.weight,
        bodyFat: item.bodyFat,
        height: item.height,
        bmi: item.bmi,
        waist: item.waist,
        hip: item.hip,
        shoulder: item.shoulder,
        arm: item.arm,
        leg: item.leg,
        calf: item.calf,
        note: item.note,
        createdAt: daysAgo(item.daysAgo),
      },
    });
  }
}

async function createActiveWeeklyProgram(clientId) {
  const program = await prisma.workoutProgram.create({
    data: {
      clientId,
      title: "Kişiye Özel Haftalık Program",
      description: "Trainer tarafından oluşturulan aktif haftalık program.",
      startDate: daysAgo(60),
      isActive: true,
      days: {
        create: [
          {
            dayName: "Pazartesi",
            focus: "Alt Vücut",
            note: "Bacak ve kalça odaklı antrenman.",
            exercises: {
              create: [
                {
                  name: "Squat",
                  sets: 4,
                  reps: 12,
                  description: "Kontrollü tempo ile uygulanır.",
                  status: "PLANNED",
                  orderIndex: 1,
                },
                {
                  name: "Leg Press",
                  sets: 4,
                  reps: 10,
                  description: "Diz kontrolüne dikkat edilir.",
                  status: "PLANNED",
                  orderIndex: 2,
                },
                {
                  name: "Walking Lunge",
                  sets: 3,
                  reps: 12,
                  description: "Her bacak için tekrar uygulanır.",
                  status: "PLANNED",
                  orderIndex: 3,
                },
              ],
            },
          },
          {
            dayName: "Salı",
            focus: "Kardiyo",
            note: "Yağ yakımı ve kondisyon odaklı gün.",
            exercises: {
              create: [
                {
                  name: "Treadmill",
                  sets: 1,
                  reps: null,
                  duration: "35 dk",
                  description: "Orta tempo yürüyüş.",
                  status: "PLANNED",
                  orderIndex: 1,
                },
                {
                  name: "Bisiklet",
                  sets: 1,
                  reps: null,
                  duration: "20 dk",
                  description: "Sabit bisiklet.",
                  status: "PLANNED",
                  orderIndex: 2,
                },
              ],
            },
          },
          {
            dayName: "Çarşamba",
            focus: "Üst Vücut",
            note: "Göğüs, sırt ve omuz odaklı antrenman.",
            exercises: {
              create: [
                {
                  name: "Bench Press",
                  sets: 4,
                  reps: 10,
                  description: "Kontrollü iniş ve itiş.",
                  status: "PLANNED",
                  orderIndex: 1,
                },
                {
                  name: "Lat Pulldown",
                  sets: 4,
                  reps: 12,
                  description: "Sırt kaslarına odaklanılır.",
                  status: "PLANNED",
                  orderIndex: 2,
                },
                {
                  name: "Shoulder Press",
                  sets: 3,
                  reps: 12,
                  description: "Omuz stabilitesi korunur.",
                  status: "PLANNED",
                  orderIndex: 3,
                },
              ],
            },
          },
          {
            dayName: "Perşembe",
            focus: "Core & Esneklik",
            note: "Karın bölgesi ve mobilite çalışması.",
            exercises: {
              create: [
                {
                  name: "Plank",
                  sets: 3,
                  reps: 1,
                  duration: "45 sn",
                  description: "Core stabilitesi.",
                  status: "PLANNED",
                  orderIndex: 1,
                },
                {
                  name: "Russian Twist",
                  sets: 3,
                  reps: 20,
                  description: "Kontrollü rotasyon.",
                  status: "PLANNED",
                  orderIndex: 2,
                },
              ],
            },
          },
          {
            dayName: "Cuma",
            focus: "Full Body",
            note: "Tüm vücut kuvvet ve kondisyon günü.",
            exercises: {
              create: [
                {
                  name: "Deadlift",
                  sets: 4,
                  reps: 8,
                  description: "Form kontrolü önemlidir.",
                  status: "PLANNED",
                  orderIndex: 1,
                },
                {
                  name: "Push Up",
                  sets: 3,
                  reps: 15,
                  description: "Vücut ağırlığı ile uygulanır.",
                  status: "PLANNED",
                  orderIndex: 2,
                },
                {
                  name: "Burpee",
                  sets: 3,
                  reps: 12,
                  description: "Kondisyon odaklı hareket.",
                  status: "PLANNED",
                  orderIndex: 3,
                },
              ],
            },
          },
        ],
      },
    },
    include: {
      days: {
        include: {
          exercises: {
            orderBy: {
              orderIndex: "asc",
            },
          },
        },
        orderBy: {
          id: "asc",
        },
      },
    },
  });

  return program;
}

async function createHistoricalSetCompletions(
  clientId,
  program,
  completionRatio
) {
  const allExercises = program.days.flatMap((day) => day.exercises);

  const allSetTargets = [];

  for (const exercise of allExercises) {
    const setCount = exercise.sets || 1;

    for (let setNumber = 1; setNumber <= setCount; setNumber++) {
      allSetTargets.push({
        exerciseId: exercise.id,
        setNumber,
      });
    }
  }

  const completedCount = Math.round(allSetTargets.length * completionRatio);

  for (let index = 0; index < completedCount; index++) {
    const target = allSetTargets[index];

    const weekOffset = 7 - (index % 8);
    const completedAt = daysAgo(weekOffset * 7);

    await prisma.exerciseSetCompletion.create({
      data: {
        clientId,
        exerciseId: target.exerciseId,
        setNumber: target.setNumber,
        isCompleted: true,
        weight: 15 + index,
        completedAt,
      },
    });
  }
}

async function createWorkoutDayCompletions(clientId, program) {
  for (let index = 0; index < program.days.length; index++) {
    if (index < 3) {
      await prisma.workoutCompletion.create({
        data: {
          clientId,
          dayId: program.days[index].id,
          completedAt: daysAgo((index + 1) * 7),
        },
      });
    }
  }
}

async function createAppointments(clientId, trainerId) {
  const appointments = [
    {
      daysAgo: 21,
      startTime: "10:00",
      endTime: "11:00",
      status: "APPROVED",
      note: "Geçmiş özel ders.",
    },
    {
      daysAgo: 14,
      startTime: "12:00",
      endTime: "13:00",
      status: "APPROVED",
      note: "Geçmiş özel ders.",
    },
    {
      daysAgo: 7,
      startTime: "15:00",
      endTime: "16:00",
      status: "APPROVED",
      note: "Geçmiş özel ders.",
    },
    {
      daysAgo: -2,
      startTime: "11:00",
      endTime: "12:00",
      status: "PENDING",
      note: "Yaklaşan özel ders.",
    },
  ];

  for (const item of appointments) {
    await prisma.appointment.create({
      data: {
        clientId,
        trainerId,
        date: daysAgo(item.daysAgo),
        startTime: item.startTime,
        endTime: item.endTime,
        status: item.status,
        note: item.note,
      },
    });
  }
}

async function createNotifications({ userId, role }) {
  await prisma.notification.deleteMany({
    where: { userId },
  });

  if (role === "CLIENT") {
    await prisma.notification.createMany({
      data: [
        {
          userId,
          title: "Program Güncellendi",
          message:
            "Antrenörün haftalık antrenman programını güncelledi. Program ekranından detayları inceleyebilirsin.",
          type: "PROGRAM",
        },
        {
          userId,
          title: "Özel Ders Talebi",
          message:
            "Yaklaşan özel ders talebin oluşturuldu. Antrenör onayı bekleniyor.",
          type: "APPOINTMENT",
        },
        {
          userId,
          title: "FitBot Analizi Hazır",
          message:
            "Son ölçüm ve antrenman verilerine göre gelişim yorumların hazır.",
          type: "ANALYTICS",
        },
      ],
    });
  }

  if (role === "TRAINER") {
    await prisma.notification.createMany({
      data: [
        {
          userId,
          title: "Yeni Özel Ders Talebi",
          message:
            "Bir danışanın özel ders talebi oluşturdu. Bildirimler veya bugünkü ders programından kontrol edebilirsin.",
          type: "APPOINTMENT",
        },
        {
          userId,
          title: "Danışan Programı",
          message: "Danışanlarının programlarını kontrol etmeyi unutma.",
          type: "PROGRAM",
        },
        {
          userId,
          title: "AI Program Talebi",
          message:
            "İleride eklenecek AI program önerileri bu alanda görüntülenecek.",
          type: "AI_PROGRAM",
        },
      ],
    });
  }
}

async function main() {
  const admin = await upsertUser({
    fullName: "Sistem Admin",
    email: "admin@gym.com",
    phone: "5550000000",
    role: "ADMIN",
  });

  console.log("Admin hazır:", admin.email);

  const { user: aliUser, trainer: aliTrainer } = await createTrainer({
    fullName: "Ali Yılmaz",
    email: "ali@gym.com",
    phone: "5551111111",
    specialty: "Kuvvet ve Fitness",
    bio: "Kilo kontrolü, kas gelişimi ve kişiye özel antrenman programları.",
  });

  const { user: elifUser, trainer: elifTrainer } = await createTrainer({
    fullName: "Elif Demir",
    email: "elif@gym.com",
    phone: "5552222222",
    specialty: "Pilates ve Fonksiyonel Antrenman",
    bio: "Duruş, esneklik ve yağ yakımı odaklı antrenmanlar.",
  });

  const { user: mertUser, trainer: mertTrainer } = await createTrainer({
    fullName: "Mert Koç",
    email: "mert@gym.com",
    phone: "5553333333",
    specialty: "Kardiyo ve Performans",
    bio: "Dayanıklılık, kondisyon ve atletik performans geliştirme.",
  });

  const { user: zehraUser, client: zehra } = await createClient({
    fullName: "Zehra Kırdağ",
    email: "zehra@gym.com",
    phone: "5554444444",
    trainerId: aliTrainer.id,
    gender: "Kadın",
    birthDate: "2003-11-13",
    height: 165,
    startWeight: 92,
    targetWeight: 75,
    goal: "Kilo Verme",
    activityLevel: "Orta",
    healthNotes: "Genel sağlık durumu iyi. Düzenli egzersiz yapabilir.",
    injuryNotes: "Bilinen sakatlık bulunmuyor.",
  });

  const { user: silaUser, client: sila } = await createClient({
    fullName: "Sıla Aydın",
    email: "sila@gym.com",
    phone: "5271936282",
    trainerId: aliTrainer.id,
    gender: "Kadın",
    birthDate: "2002-04-18",
    height: 168,
    startWeight: 74,
    targetWeight: 64,
    goal: "Kilo Verme ve Sıkılaşma",
    activityLevel: "Orta",
    healthNotes:
      "Genel sağlık durumu iyi. Kardiyo ve direnç antrenmanına uygundur.",
    injuryNotes: "Bilinen sakatlık bulunmuyor.",
  });

  const { user: ayseUser, client: ayse } = await createClient({
    fullName: "Ayşe Kaya",
    email: "ayse@gym.com",
    phone: "5555555555",
    trainerId: elifTrainer.id,
    gender: "Kadın",
    birthDate: "1998-05-20",
    height: 170,
    startWeight: 78,
    targetWeight: 65,
    goal: "Yağ Yakımı",
    activityLevel: "Başlangıç",
    healthNotes:
      "Hipotiroid geçmişi mevcut. Program yoğunluğu kontrollü artırılmalı.",
    injuryNotes: "Sol diz hassasiyeti bulunuyor.",
  });

  const { user: mehmetUser, client: mehmet } = await createClient({
    fullName: "Mehmet Can",
    email: "mehmet@gym.com",
    phone: "5556666666",
    trainerId: mertTrainer.id,
    gender: "Erkek",
    birthDate: "1995-02-10",
    height: 180,
    startWeight: 96,
    targetWeight: 84,
    goal: "Kas Kazanımı",
    activityLevel: "İleri",
    healthNotes: "Herhangi bir kronik rahatsızlık bulunmuyor.",
    injuryNotes:
      "Geçmiş omuz sakatlığı nedeniyle press hareketlerinde dikkatli çalışılmalı.",
  });

  await createMeasurements(zehra.id, [
    { daysAgo: 70, weight: 92, bodyFat: 36, height: 165, bmi: 33.8, waist: 104, hip: 116, shoulder: 98, arm: 34, leg: 62, calf: 39, note: "Başlangıç ölçümü" },
    { daysAgo: 56, weight: 89, bodyFat: 34, height: 165, bmi: 32.7, waist: 100, hip: 113, shoulder: 97, arm: 33, leg: 61, calf: 38, note: "İlk gelişim" },
    { daysAgo: 42, weight: 86.5, bodyFat: 32, height: 165, bmi: 31.8, waist: 97, hip: 110, shoulder: 96, arm: 32, leg: 60, calf: 37, note: "Düzenli ilerleme" },
    { daysAgo: 28, weight: 84, bodyFat: 29, height: 165, bmi: 30.9, waist: 93, hip: 107, shoulder: 95, arm: 31, leg: 59, calf: 36, note: "Performans artışı" },
    { daysAgo: 14, weight: 82.5, bodyFat: 27.5, height: 165, bmi: 30.3, waist: 90, hip: 105, shoulder: 94, arm: 30.5, leg: 58, calf: 36, note: "Yağ oranı düşüşü" },
    { daysAgo: 0, weight: 81, bodyFat: 26, height: 165, bmi: 29.8, waist: 88, hip: 103, shoulder: 94, arm: 30, leg: 57, calf: 35, note: "Güncel ölçüm" },
  ]);

  await createMeasurements(sila.id, [
    { daysAgo: 70, weight: 74, bodyFat: 31, height: 168, bmi: 26.2, waist: 88, hip: 104, shoulder: 92, arm: 29, leg: 57, calf: 35, note: "Başlangıç ölçümü" },
    { daysAgo: 56, weight: 72.8, bodyFat: 29.8, height: 168, bmi: 25.8, waist: 86, hip: 102, shoulder: 92, arm: 28.5, leg: 56, calf: 35, note: "İlk gelişim" },
    { daysAgo: 42, weight: 71.4, bodyFat: 28.5, height: 168, bmi: 25.3, waist: 84, hip: 100, shoulder: 91, arm: 28, leg: 55, calf: 34, note: "Düzenli ilerleme" },
    { daysAgo: 28, weight: 70.2, bodyFat: 27.2, height: 168, bmi: 24.9, waist: 82, hip: 98, shoulder: 91, arm: 27.5, leg: 54.5, calf: 34, note: "Yağ oranı düşüşü" },
    { daysAgo: 14, weight: 68.9, bodyFat: 26, height: 168, bmi: 24.4, waist: 80, hip: 97, shoulder: 90, arm: 27, leg: 54, calf: 33.5, note: "Performans artışı" },
    { daysAgo: 0, weight: 67.8, bodyFat: 24.8, height: 168, bmi: 24.0, waist: 78, hip: 95, shoulder: 90, arm: 27, leg: 53, calf: 33, note: "Güncel ölçüm" },
  ]);

  await createMeasurements(ayse.id, [
    { daysAgo: 56, weight: 78, bodyFat: 31, height: 170, bmi: 27, waist: 86, hip: 105, shoulder: 91, arm: 29, leg: 58, calf: 35, note: "Başlangıç" },
    { daysAgo: 28, weight: 74, bodyFat: 28, height: 170, bmi: 25.6, waist: 81, hip: 101, shoulder: 90, arm: 28, leg: 56, calf: 34, note: "Gelişim" },
    { daysAgo: 0, weight: 71.5, bodyFat: 25.5, height: 170, bmi: 24.7, waist: 77, hip: 98, shoulder: 89, arm: 27, leg: 55, calf: 33, note: "Güncel" },
  ]);

  await createMeasurements(mehmet.id, [
    { daysAgo: 56, weight: 96, bodyFat: 28, height: 180, bmi: 29.6, waist: 102, hip: 108, shoulder: 112, arm: 36, leg: 64, calf: 40, note: "Başlangıç" },
    { daysAgo: 28, weight: 93, bodyFat: 25.5, height: 180, bmi: 28.7, waist: 98, hip: 105, shoulder: 113, arm: 37, leg: 64, calf: 39, note: "Gelişim" },
    { daysAgo: 0, weight: 90, bodyFat: 23, height: 180, bmi: 27.8, waist: 94, hip: 102, shoulder: 114, arm: 38, leg: 65, calf: 39, note: "Güncel" },
  ]);

  const zehraProgram = await createActiveWeeklyProgram(zehra.id);
  const silaProgram = await createActiveWeeklyProgram(sila.id);
  const ayseProgram = await createActiveWeeklyProgram(ayse.id);
  const mehmetProgram = await createActiveWeeklyProgram(mehmet.id);

  await createHistoricalSetCompletions(zehra.id, zehraProgram, 0.88);
  await createHistoricalSetCompletions(sila.id, silaProgram, 0.82);
  await createHistoricalSetCompletions(ayse.id, ayseProgram, 0.76);
  await createHistoricalSetCompletions(mehmet.id, mehmetProgram, 0.68);

  await createWorkoutDayCompletions(zehra.id, zehraProgram);
  await createWorkoutDayCompletions(sila.id, silaProgram);
  await createWorkoutDayCompletions(ayse.id, ayseProgram);
  await createWorkoutDayCompletions(mehmet.id, mehmetProgram);

  await createAppointments(zehra.id, aliTrainer.id);
  await createAppointments(sila.id, aliTrainer.id);
  await createAppointments(ayse.id, elifTrainer.id);
  await createAppointments(mehmet.id, mertTrainer.id);

  await createNotifications({ userId: zehraUser.id, role: "CLIENT" });
  await createNotifications({ userId: silaUser.id, role: "CLIENT" });
  await createNotifications({ userId: ayseUser.id, role: "CLIENT" });
  await createNotifications({ userId: mehmetUser.id, role: "CLIENT" });

  await createNotifications({ userId: aliUser.id, role: "TRAINER" });
  await createNotifications({ userId: elifUser.id, role: "TRAINER" });
  await createNotifications({ userId: mertUser.id, role: "TRAINER" });

  console.log("Demo analiz ve bildirim verileri başarıyla oluşturuldu.");
  console.log("Giriş bilgileri:");
  console.log("Admin: admin@gym.com / 123456");
  console.log("Client: zehra@gym.com / 123456");
  console.log("Client: sila@gym.com / 123456");
  console.log("Trainer: ali@gym.com / 123456");
}

main()
  .catch((error) => {
    console.error("SEED ERROR:", error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });