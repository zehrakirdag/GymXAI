const express = require("express");
const router = express.Router();
const prisma = require("../prisma");
const { spawn } = require("child_process");
const path = require("path");

const PYTHON_PATH =
  "C:\\Users\\Zehra\\AppData\\Local\\Programs\\Python\\Python311\\python.exe";

function normalizeGoal(goal) {
  if (!goal) return "GENERAL_FITNESS";

  const value = goal.toString().toLowerCase();

  if (
    value.includes("kilo") ||
    value.includes("zayıf") ||
    value.includes("zayif") ||
    value.includes("yağ") ||
    value.includes("yag") ||
    value.includes("weight")
  ) {
    return "WEIGHT_LOSS";
  }

  if (
    value.includes("kas") ||
    value.includes("güç") ||
    value.includes("guc") ||
    value.includes("muscle") ||
    value.includes("gain")
  ) {
    return "MUSCLE_GAIN";
  }

  return "GENERAL_FITNESS";
}

function normalizeActivityLevel(activityLevel) {
  if (!activityLevel) return "MEDIUM";

  const value = activityLevel.toString().toLowerCase();

  if (
    value.includes("düşük") ||
    value.includes("dusuk") ||
    value.includes("az") ||
    value.includes("low")
  ) {
    return "LOW";
  }

  if (
    value.includes("yüksek") ||
    value.includes("yuksek") ||
    value.includes("aktif") ||
    value.includes("high")
  ) {
    return "HIGH";
  }

  return "MEDIUM";
}

function normalizeGender(gender) {
  if (!gender) return 0;

  const value = gender.toString().toLowerCase();

  if (
    value.includes("erkek") ||
    value.includes("male") ||
    value === "1"
  ) {
    return 1;
  }

  return 0;
}

function calculateAge(birthDate) {
  if (!birthDate) return 25;

  const birth = new Date(birthDate);
  const today = new Date();

  let age = today.getFullYear() - birth.getFullYear();

  const monthDiff = today.getMonth() - birth.getMonth();
  const dayDiff = today.getDate() - birth.getDate();

  if (monthDiff < 0 || (monthDiff === 0 && dayDiff < 0)) {
    age--;
  }

  if (Number.isNaN(age) || age < 18 || age > 75) {
    return 25;
  }

  return age;
}

function calculateProgramProgress(clientProfile) {
  const programs = clientProfile.programs || [];

  if (programs.length === 0) return 0;

  const program = programs[0];
  const days = program.days || [];

  let totalSets = 0;
  let completedSets = 0;

  for (const day of days) {
    const exercises = day.exercises || [];

    for (const exercise of exercises) {
      const setCount = Number(exercise.sets || 0);
      const setCompletions = exercise.setCompletions || [];

      for (let setNumber = 1; setNumber <= setCount; setNumber++) {
        totalSets++;

        const isCompleted = setCompletions.some((completion) => {
          return (
            completion.clientId === clientProfile.id &&
            completion.setNumber === setNumber &&
            completion.isCompleted === true
          );
        });

        if (isCompleted) completedSets++;
      }
    }
  }

  if (totalSets === 0) return 0;

  return Math.round((completedSets / totalSets) * 100);
}

async function predictProgramType(clientProfile, latestMeasurement) {
  return new Promise((resolve, reject) => {
    const currentWeight =
      latestMeasurement?.weight || clientProfile.startWeight || 70;

    const targetWeight = clientProfile.targetWeight || currentWeight;

    const bmi =
      latestMeasurement?.bmi ||
      (clientProfile.height && currentWeight
        ? currentWeight / Math.pow(clientProfile.height / 100, 2)
        : 25);

    const payload = {
      age: calculateAge(clientProfile.birthDate),
      gender: normalizeGender(clientProfile.gender),
      bmi: Number(bmi),
      goal: normalizeGoal(clientProfile.goal),
      activityLevel: normalizeActivityLevel(clientProfile.activityLevel),
      hasHealthIssue:
        clientProfile.healthNotes &&
        clientProfile.healthNotes.trim() !== ""
          ? 1
          : 0,
      hasInjury:
        clientProfile.injuryNotes &&
        clientProfile.injuryNotes.trim() !== ""
          ? 1
          : 0,
      weightChange: Number(
        currentWeight - (clientProfile.startWeight || currentWeight)
      ),
      targetWeightDiff: Number(targetWeight - currentWeight),
      programProgress: calculateProgramProgress(clientProfile),
    };

    const pythonProcess = spawn(PYTHON_PATH, [
      path.join(__dirname, "../../ml/predict_program.py"),
      JSON.stringify(payload),
    ]);

    let result = "";
    let errorResult = "";

    pythonProcess.stdout.on("data", (data) => {
      result += data.toString();
    });

    pythonProcess.stderr.on("data", (data) => {
      errorResult += data.toString();
    });

    pythonProcess.on("close", (code) => {
      if (code !== 0) {
        return reject(
          new Error(
            errorResult || "Python modeli çalıştırılırken hata oluştu"
          )
        );
      }

      try {
        const parsed = JSON.parse(result);

        if (parsed.error) {
          return reject(new Error(parsed.detail || parsed.error));
        }

        return resolve(parsed);
      } catch (err) {
        return reject(
          new Error(
            `Python çıktısı okunamadı: ${result}`
          )
        );
      }
    });
  });
}

function buildProgramFromType(programType) {
  const programs = {
    WEIGHT_LOSS_BEGINNER: {
      title: "AI Yağ Yakımı Başlangıç Programı",
      description:
        "Random Forest modeli tarafından önerilen başlangıç seviye yağ yakımı ve kondisyon programı.",
      aiReason:
        "Model; BMI, hedef, aktivite seviyesi ve ilerleme durumuna göre başlangıç seviye yağ yakımı programını önerdi.",
      weeklyPlan: [
        {
          day: "Pazartesi",
          focus: "Kardiyo + Full Body",
          exercises: [
            { name: "Isınma Yürüyüşü", sets: 1, reps: 10, duration: "10 dakika" },
            { name: "Squat", sets: 3, reps: 12 },
            { name: "Chest Press", sets: 3, reps: 10 },
            { name: "Lat Pulldown", sets: 3, reps: 10 },
            { name: "Kardiyo", sets: 1, reps: 15, duration: "15 dakika" },
          ],
        },
        {
          day: "Çarşamba",
          focus: "Alt Vücut + Core",
          exercises: [
            { name: "Bisiklet", sets: 1, reps: 10, duration: "10 dakika" },
            { name: "Leg Press", sets: 3, reps: 12 },
            { name: "Leg Curl", sets: 3, reps: 12 },
            { name: "Plank", sets: 3, reps: 30, duration: "30 saniye" },
          ],
        },
        {
          day: "Cuma",
          focus: "Genel Kondisyon",
          exercises: [
            { name: "Eliptik Bisiklet", sets: 1, reps: 10, duration: "10 dakika" },
            { name: "Shoulder Press", sets: 3, reps: 10 },
            { name: "Seated Row", sets: 3, reps: 10 },
            { name: "Kardiyo", sets: 1, reps: 20, duration: "20 dakika" },
          ],
        },
      ],
    },

    WEIGHT_LOSS_INTERMEDIATE: {
      title: "AI Yağ Yakımı Orta Seviye Programı",
      description:
        "Random Forest modeli tarafından önerilen orta seviye yağ yakımı ve direnç antrenmanı programı.",
      aiReason:
        "Model; kullanıcının ilerleme oranı, aktivite seviyesi ve hedef kilo farkına göre orta seviye yağ yakımı programını önerdi.",
      weeklyPlan: [
        {
          day: "Pazartesi",
          focus: "HIIT + Üst Vücut",
          exercises: [
            { name: "Koşu Bandı", sets: 1, reps: 12, duration: "12 dakika" },
            { name: "Chest Press", sets: 4, reps: 10 },
            { name: "Lat Pulldown", sets: 4, reps: 10 },
            { name: "Mountain Climber", sets: 3, reps: 20 },
          ],
        },
        {
          day: "Çarşamba",
          focus: "Alt Vücut",
          exercises: [
            { name: "Squat", sets: 4, reps: 12 },
            { name: "Leg Press", sets: 4, reps: 12 },
            { name: "Walking Lunge", sets: 3, reps: 12 },
            { name: "Plank", sets: 3, reps: 45, duration: "45 saniye" },
          ],
        },
        {
          day: "Cuma",
          focus: "Kardiyo + Core",
          exercises: [
            { name: "Eliptik Bisiklet", sets: 1, reps: 20, duration: "20 dakika" },
            { name: "Seated Row", sets: 3, reps: 12 },
            { name: "Russian Twist", sets: 3, reps: 20 },
            { name: "Kardiyo", sets: 1, reps: 20, duration: "20 dakika" },
          ],
        },
      ],
    },

    MUSCLE_GAIN: {
      title: "AI Kas Kazanımı Programı",
      description:
        "Random Forest modeli tarafından önerilen kuvvet ve hipertrofi odaklı program.",
      aiReason:
        "Model; hedef, BMI, aktivite seviyesi ve kilo değişimine göre kas kazanımı programını önerdi.",
      weeklyPlan: [
        {
          day: "Pazartesi",
          focus: "Üst Vücut",
          exercises: [
            { name: "Bench Press", sets: 4, reps: 8 },
            { name: "Lat Pulldown", sets: 4, reps: 10 },
            { name: "Shoulder Press", sets: 3, reps: 10 },
            { name: "Biceps Curl", sets: 3, reps: 12 },
          ],
        },
        {
          day: "Çarşamba",
          focus: "Alt Vücut",
          exercises: [
            { name: "Squat", sets: 4, reps: 8 },
            { name: "Leg Press", sets: 4, reps: 10 },
            { name: "Leg Curl", sets: 3, reps: 12 },
            { name: "Calf Raise", sets: 3, reps: 15 },
          ],
        },
        {
          day: "Cuma",
          focus: "Push / Pull",
          exercises: [
            { name: "Incline Dumbbell Press", sets: 4, reps: 10 },
            { name: "Seated Row", sets: 4, reps: 10 },
            { name: "Triceps Pushdown", sets: 3, reps: 12 },
            { name: "Lateral Raise", sets: 3, reps: 12 },
          ],
        },
      ],
    },

    LOW_IMPACT: {
      title: "AI Düşük Etkili Güvenli Program",
      description:
        "Random Forest modeli tarafından önerilen düşük etkili ve kontrollü egzersiz programı.",
      aiReason:
        "Model; sağlık notları, sakatlık bilgisi, yaş ve aktivite seviyesine göre düşük etkili programı önerdi.",
      weeklyPlan: [
        {
          day: "Pazartesi",
          focus: "Düşük Etkili Full Body",
          exercises: [
            { name: "Yavaş Tempo Yürüyüş", sets: 1, reps: 10, duration: "10 dakika" },
            { name: "Seated Chest Press", sets: 2, reps: 12 },
            { name: "Seated Row", sets: 2, reps: 12 },
            { name: "Denge Egzersizi", sets: 2, reps: 30, duration: "30 saniye" },
          ],
        },
        {
          day: "Çarşamba",
          focus: "Mobilite + Core",
          exercises: [
            { name: "Bisiklet", sets: 1, reps: 8, duration: "8 dakika" },
            { name: "Leg Extension", sets: 2, reps: 12 },
            { name: "Wall Push Up", sets: 2, reps: 10 },
            { name: "Esneme", sets: 1, reps: 10, duration: "10 dakika" },
          ],
        },
        {
          day: "Cuma",
          focus: "Kontrollü Kondisyon",
          exercises: [
            { name: "Eliptik Bisiklet", sets: 1, reps: 8, duration: "8 dakika" },
            { name: "Light Dumbbell Press", sets: 2, reps: 12 },
            { name: "Cable Row", sets: 2, reps: 12 },
            { name: "Nefes Egzersizi", sets: 1, reps: 5, duration: "5 dakika" },
          ],
        },
      ],
    },

    GENERAL_FITNESS: {
      title: "AI Genel Fitness Programı",
      description:
        "Random Forest modeli tarafından önerilen genel kondisyon ve kuvvet programı.",
      aiReason:
        "Model; kullanıcının genel hedefleri, aktivite seviyesi ve program ilerlemesine göre dengeli bir fitness programı önerdi.",
      weeklyPlan: [
        {
          day: "Pazartesi",
          focus: "Full Body",
          exercises: [
            { name: "Isınma Yürüyüşü", sets: 1, reps: 10, duration: "10 dakika" },
            { name: "Squat", sets: 3, reps: 12 },
            { name: "Chest Press", sets: 3, reps: 10 },
            { name: "Seated Row", sets: 3, reps: 10 },
          ],
        },
        {
          day: "Çarşamba",
          focus: "Alt Vücut + Core",
          exercises: [
            { name: "Bisiklet", sets: 1, reps: 10, duration: "10 dakika" },
            { name: "Leg Press", sets: 3, reps: 12 },
            { name: "Plank", sets: 3, reps: 30, duration: "30 saniye" },
            { name: "Shoulder Press", sets: 3, reps: 10 },
          ],
        },
        {
          day: "Cuma",
          focus: "Kondisyon",
          exercises: [
            { name: "Eliptik Bisiklet", sets: 1, reps: 12, duration: "12 dakika" },
            { name: "Lat Pulldown", sets: 3, reps: 10 },
            { name: "Leg Curl", sets: 3, reps: 12 },
            { name: "Kardiyo", sets: 1, reps: 15, duration: "15 dakika" },
          ],
        },
      ],
    },
  };

  return programs[programType] || programs.GENERAL_FITNESS;
}

router.post("/request-program/:clientProfileId", async (req, res) => {
  try {
    const clientProfileId = Number(req.params.clientProfileId);

    const clientProfile = await prisma.clientProfile.findUnique({
      where: { id: clientProfileId },
      include: {
        user: true,
        trainer: {
          include: {
            user: true,
          },
        },
        measurements: {
          orderBy: {
            createdAt: "desc",
          },
          take: 1,
        },
        programs: {
          where: {
            isActive: true,
          },
          include: {
            days: {
              include: {
                exercises: {
                  include: {
                    setCompletions: true,
                  },
                },
              },
            },
          },
          take: 1,
        },
      },
    });

    if (!clientProfile) {
      return res.status(404).json({ message: "Danışan profili bulunamadı" });
    }

    if (!clientProfile.trainerId || !clientProfile.trainer) {
      return res.status(400).json({
        message: "Bu danışana atanmış bir antrenör bulunmuyor",
      });
    }

    const latestMeasurement = clientProfile.measurements[0];

    const prediction = await predictProgramType(
      clientProfile,
      latestMeasurement
    );

    const programTemplate = buildProgramFromType(prediction.programType);

    const suggestedProgram = {
      programType: prediction.programType,
      confidence: prediction.confidence,
      title: programTemplate.title,
      description: programTemplate.description,
      weeklyPlan: programTemplate.weeklyPlan,
    };

    const request = await prisma.aIProgramRequest.create({
      data: {
        clientId: clientProfile.id,
        trainerId: clientProfile.trainerId,
        status: "PENDING",
        programType: prediction.programType,
        goal: clientProfile.goal,
        activityLevel: clientProfile.activityLevel,
        bmi: latestMeasurement?.bmi || null,
        healthNotes: clientProfile.healthNotes,
        injuryNotes: clientProfile.injuryNotes,
        aiReason: `${programTemplate.aiReason} Model güven skoru: ${(
          prediction.confidence * 100
        ).toFixed(1)}%.`,
        suggestedProgram,
      },
    });

    await prisma.notification.create({
      data: {
        userId: clientProfile.trainer.userId,
        title: "AI Program Talebi 🤖",
        message: `${clientProfile.user.fullName} için Random Forest modeliyle AI destekli program önerisi oluşturuldu. Lütfen inceleyip onaylayın.`,
        type: "AI_PROGRAM",
      },
    });

    return res.status(201).json({
      message:
        "Random Forest modeli ile AI program önerisi oluşturuldu ve antrenöre gönderildi",
      request,
    });
  } catch (error) {
    console.error("AI PROGRAM REQUEST ERROR:", error);
    return res.status(500).json({
      message: "AI program önerisi oluşturulurken hata oluştu",
      error: error.message,
    });
  }
});

router.get("/trainer/:trainerProfileId/requests", async (req, res) => {
  try {
    const trainerProfileId = Number(req.params.trainerProfileId);

    const requests = await prisma.aIProgramRequest.findMany({
      where: {
        trainerId: trainerProfileId,
      },
      include: {
        client: {
          include: {
            user: true,
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    return res.status(200).json(requests);
  } catch (error) {
    console.error("AI REQUEST LIST ERROR:", error);
    return res.status(500).json({
      message: "AI program talepleri alınamadı",
      error: error.message,
    });
  }
});

router.put("/requests/:requestId/status", async (req, res) => {
  try {
    const requestId = Number(req.params.requestId);
    const { status, trainerNote } = req.body;

    if (!["APPROVED", "REJECTED"].includes(status)) {
      return res.status(400).json({
        message: "Geçersiz durum",
      });
    }

    const existingRequest = await prisma.aIProgramRequest.findUnique({
      where: {
        id: requestId,
      },
      include: {
        client: {
          include: {
            user: true,
          },
        },
      },
    });

    if (!existingRequest) {
      return res.status(404).json({
        message: "AI program talebi bulunamadı",
      });
    }

    const request = await prisma.aIProgramRequest.update({
      where: {
        id: requestId,
      },
      data: {
        status,
        trainerNote,
      },
      include: {
        client: {
          include: {
            user: true,
          },
        },
      },
    });

    if (status === "APPROVED") {
      const suggestedProgram = existingRequest.suggestedProgram;
      const weeklyPlan = suggestedProgram.weeklyPlan || [];

      await prisma.workoutProgram.updateMany({
        where: {
          clientId: existingRequest.clientId,
          isActive: true,
        },
        data: {
          isActive: false,
        },
      });

      await prisma.workoutProgram.create({
        data: {
          clientId: existingRequest.clientId,
          title: suggestedProgram.title || "AI Antrenman Programı",
          description:
            suggestedProgram.description ||
            "Random Forest modeli tarafından önerilen AI destekli antrenman programı.",
          startDate: new Date(),
          isActive: true,
          days: {
            create: weeklyPlan.map((day) => ({
              dayName: day.day,
              focus: day.focus,
              note: "AI modeli tarafından önerildi, antrenör tarafından onaylandı.",
              exercises: {
                create: (day.exercises || []).map((exercise, index) => ({
                  name: exercise.name,
                  sets: Number(exercise.sets || 1),
                  reps:
                    typeof exercise.reps === "number"
                      ? exercise.reps
                      : null,
                  duration:
                    typeof exercise.reps === "string"
                      ? exercise.reps
                      : exercise.duration || null,
                  description: "AI önerisi",
                  status: "PLANNED",
                  orderIndex: index,
                })),
              },
            })),
          },
        },
      });
    }

    await prisma.notification.create({
      data: {
        userId: request.client.userId,
        title:
          status === "APPROVED"
            ? "AI Programın Onaylandı ✅"
            : "AI Program Talebin Reddedildi ❌",
        message:
          status === "APPROVED"
            ? "Antrenörün AI tarafından önerilen programı onayladı. Yeni programın aktif hale getirildi."
            : `Antrenörün AI program talebini reddetti. ${
                trainerNote ? "Not: " + trainerNote : ""
              }`,
        type: "AI_PROGRAM",
      },
    });

    return res.status(200).json({
      message:
        status === "APPROVED"
          ? "AI program talebi onaylandı ve aktif programa dönüştürüldü"
          : "AI program talebi reddedildi",
      request,
    });
  } catch (error) {
    console.error("AI REQUEST STATUS ERROR:", error);
    return res.status(500).json({
      message: "AI program talebi güncellenemedi",
      error: error.message,
    });
  }
});

module.exports = router;