const express = require("express");
const prisma = require("../prisma");

const router = express.Router();

// Client kendi profilini getir
router.get("/:clientUserId/profile", async (req, res) => {
  try {
    const clientUserId = Number(req.params.clientUserId);

    const clientProfile = await prisma.clientProfile.findUnique({
      where: { userId: clientUserId },
      include: {
        user: true,
        trainer: {
          include: {
            user: true,
            workingHours: {
              include: { specialLessons: true },
              orderBy: { id: "asc" },
            },
          },
        },
        measurements: { orderBy: { createdAt: "desc" } },
        programs: {
          where: { isActive: true },
          include: {
            days: {
              include: {
                exercises: {
                  include: {
                    completions: true,
                    setCompletions: true,
                  },
                  orderBy: { orderIndex: "asc" },
                },
                completions: true,
              },
              orderBy: { id: "asc" },
            },
          },
          orderBy: { createdAt: "desc" },
        },
        completions: { orderBy: { completedAt: "desc" } },
        exerciseCompletions: { orderBy: { completedAt: "desc" } },
        setCompletions: { orderBy: { completedAt: "desc" } },
        appointments: { orderBy: { createdAt: "desc" } },
      },
    });

    if (!clientProfile) {
      return res.status(404).json({ message: "Danışan profili bulunamadı" });
    }

    res.status(200).json(clientProfile);
  } catch (error) {
    console.error("GET CLIENT PROFILE ERROR:", error);
    res.status(500).json({
      message: "Client profili alınamadı",
      error: error.message,
    });
  }
});

// Client analiz verilerini getir
router.get("/:clientId/analytics", async (req, res) => {
  try {
    const clientId = Number(req.params.clientId);

    const client = await prisma.clientProfile.findUnique({
      where: { id: clientId },
      include: {
        user: true,
        measurements: { orderBy: { createdAt: "asc" } },
        programs: {
          where: { isActive: true },
          include: {
            days: {
              include: {
                exercises: {
                  include: {
                    setCompletions: {
                      where: { clientId },
                      orderBy: { completedAt: "asc" },
                    },
                  },
                  orderBy: { orderIndex: "asc" },
                },
                completions: { where: { clientId } },
              },
              orderBy: { id: "asc" },
            },
          },
          orderBy: { createdAt: "desc" },
        },
        setCompletions: { orderBy: { completedAt: "asc" } },
        completions: { orderBy: { completedAt: "asc" } },
      },
    });

    if (!client) {
      return res.status(404).json({ message: "Danışan bulunamadı" });
    }

    const measurements = client.measurements;
    const firstMeasurement = measurements.length > 0 ? measurements[0] : null;
    const latestMeasurement =
      measurements.length > 0 ? measurements[measurements.length - 1] : null;

    const weightChange =
      firstMeasurement && latestMeasurement
        ? Number((latestMeasurement.weight - firstMeasurement.weight).toFixed(1))
        : 0;

    const bodyFatChange =
      firstMeasurement && latestMeasurement
        ? Number(
            (
              (latestMeasurement.bodyFat || 0) -
              (firstMeasurement.bodyFat || 0)
            ).toFixed(1)
          )
        : 0;

    const waistChange =
      firstMeasurement && latestMeasurement
        ? Number(
            (
              (latestMeasurement.waist || 0) -
              (firstMeasurement.waist || 0)
            ).toFixed(1)
          )
        : 0;

    const bmiChange =
      firstMeasurement && latestMeasurement
        ? Number(
            ((latestMeasurement.bmi || 0) - (firstMeasurement.bmi || 0)).toFixed(1)
          )
        : 0;

    const targetWeightRemaining =
      latestMeasurement && client.targetWeight
        ? Number((latestMeasurement.weight - client.targetWeight).toFixed(1))
        : null;

    const activeProgram = client.programs.length > 0 ? client.programs[0] : null;

    let totalSets = 0;
    let completedSets = 0;

    if (activeProgram) {
      for (const day of activeProgram.days) {
        for (const exercise of day.exercises) {
          const setCount = exercise.sets || 0;
          totalSets += setCount;

          for (let setNumber = 1; setNumber <= setCount; setNumber++) {
            const completed = exercise.setCompletions.some(
              (completion) =>
                completion.setNumber === setNumber &&
                completion.isCompleted === true
            );
            if (completed) completedSets++;
          }
        }
      }
    }

    const programProgress =
      totalSets === 0 ? 0 : Math.round((completedSets / totalSets) * 100);

    const weeklyMap = {};
    const monthlyMap = {};

    for (const completion of client.setCompletions) {
      const date = new Date(completion.completedAt);
      const startOfYear = new Date(date.getFullYear(), 0, 1);
      const dayOfYear =
        Math.floor((date - startOfYear) / 86400000) + startOfYear.getDay() + 1;

      const weekNumber = Math.ceil(dayOfYear / 7);
      const weekKey = `${date.getFullYear()}-W${weekNumber}`;
      const monthKey = `${date.getFullYear()}-${String(
        date.getMonth() + 1
      ).padStart(2, "0")}`;

      if (!weeklyMap[weekKey]) {
        weeklyMap[weekKey] = { week: weekKey, completedSets: 0 };
      }

      if (!monthlyMap[monthKey]) {
        monthlyMap[monthKey] = { month: monthKey, completedSets: 0 };
      }

      if (completion.isCompleted) {
        weeklyMap[weekKey].completedSets += 1;
        monthlyMap[monthKey].completedSets += 1;
      }
    }

    const weeklyPerformance = Object.values(weeklyMap);
    const monthlyPerformance = Object.values(monthlyMap);

    const measurementChart = measurements.map((item) => ({
      date: item.createdAt,
      weight: item.weight,
      bodyFat: item.bodyFat,
      waist: item.waist,
      hip: item.hip,
      shoulder: item.shoulder,
      arm: item.arm,
      leg: item.leg,
      calf: item.calf,
      bmi: item.bmi,
    }));

    const dayPerformance = activeProgram
      ? activeProgram.days.map((day) => {
          let dayTotalSets = 0;
          let dayCompletedSets = 0;

          for (const exercise of day.exercises) {
            const setCount = exercise.sets || 0;
            dayTotalSets += setCount;

            for (let setNumber = 1; setNumber <= setCount; setNumber++) {
              const completed = exercise.setCompletions.some(
                (completion) =>
                  completion.setNumber === setNumber &&
                  completion.isCompleted === true
              );

              if (completed) dayCompletedSets++;
            }
          }

          return {
            dayName: day.dayName,
            focus: day.focus,
            totalSets: dayTotalSets,
            completedSets: dayCompletedSets,
            percent:
              dayTotalSets === 0
                ? 0
                : Math.round((dayCompletedSets / dayTotalSets) * 100),
          };
        })
      : [];

    let mostActiveDay = null;

    if (dayPerformance.length > 0) {
      mostActiveDay = dayPerformance.reduce((best, current) => {
        if (!best) return current;
        return current.completedSets > best.completedSets ? current : best;
      }, null);
    }

    const latestMonth =
      monthlyPerformance.length > 0
        ? monthlyPerformance[monthlyPerformance.length - 1]
        : null;

    const previousMonth =
      monthlyPerformance.length > 1
        ? monthlyPerformance[monthlyPerformance.length - 2]
        : null;

    const monthlySetChange =
      latestMonth && previousMonth
        ? latestMonth.completedSets - previousMonth.completedSets
        : latestMonth
        ? latestMonth.completedSets
        : 0;

    const monthlySummary = {
      latestMonth: latestMonth?.month || null,
      completedSets: latestMonth?.completedSets || 0,
      previousMonthCompletedSets: previousMonth?.completedSets || 0,
      setChange: monthlySetChange,
      message:
        monthlySetChange > 0
          ? `Bu ay geçen aya göre ${monthlySetChange} set daha fazla tamamladın.`
          : monthlySetChange < 0
          ? `Bu ay geçen aya göre ${Math.abs(
              monthlySetChange
            )} set daha az tamamladın.`
          : "Bu ayki set performansın geçen ayla benzer ilerliyor.",
    };

    const coachComments = [];

    if (targetWeightRemaining !== null) {
      if (targetWeightRemaining > 0) {
        coachComments.push(
          `Hedef kilona ${targetWeightRemaining} kg kaldı. Düzenli devam edersen hedefe yaklaşman çok mümkün.`
        );
      } else {
        coachComments.push(
          "Tebrikler, hedef kilona ulaşmış ya da hedefinin altına inmiş görünüyorsun."
        );
      }
    }

    if (mostActiveDay) {
      coachComments.push(
        `Bu dönemde en verimli günün ${mostActiveDay.dayName}. Bu günde ${mostActiveDay.completedSets} set tamamlamışsın.`
      );
    }

    if (programProgress >= 80) {
      coachComments.push(
        `Program ilerlemen %${programProgress}. Disiplinin oldukça güçlü görünüyor.`
      );
    } else if (programProgress >= 50) {
      coachComments.push(
        `Program ilerlemen %${programProgress}. İyi gidiyorsun, birkaç günü daha düzenli tamamlayarak seviyeni artırabilirsin.`
      );
    } else {
      coachComments.push(
        `Program ilerlemen %${programProgress}. Küçük ama düzenli adımlarla başlamak en doğrusu.`
      );
    }

    if (weightChange < 0) {
      coachComments.push(
        `Başlangıca göre ${Math.abs(weightChange)} kg kayıp var. Bu, hedef sürecin için olumlu bir ilerleme.`
      );
    } else if (weightChange > 0) {
      coachComments.push(
        `Başlangıca göre ${weightChange} kg artış var. Bu kas kazanımı ya da beslenme düzeniyle ilgili olabilir.`
      );
    }

    if (bodyFatChange < 0) {
      coachComments.push(
        `Yağ oranında ${Math.abs(bodyFatChange)}% düşüş var. Bu çok güzel bir gelişim göstergesi.`
      );
    }

    if (bmiChange < 0) {
      coachComments.push(
        `BMI değerinde ${Math.abs(bmiChange)} puanlık düşüş var. Genel vücut kompozisyonun olumlu ilerliyor.`
      );
    }

    if (coachComments.length === 0) {
      coachComments.push(
        "Henüz yorum üretmek için yeterli veri yok. Birkaç ölçüm ve antrenman tamamlamasından sonra daha anlamlı analizler oluşacak."
      );
    }

    res.status(200).json({
      client: {
        id: client.id,
        fullName: client.user.fullName,
        height: client.height,
        startWeight: client.startWeight,
        targetWeight: client.targetWeight,
      },
      summary: {
        currentWeight: latestMeasurement?.weight || null,
        currentBodyFat: latestMeasurement?.bodyFat || null,
        currentWaist: latestMeasurement?.waist || null,
        currentBmi: latestMeasurement?.bmi || null,
        weightChange,
        bodyFatChange,
        waistChange,
        bmiChange,
        targetWeightRemaining,
        totalSets,
        completedSets,
        programProgress,
        mostActiveDay: mostActiveDay
          ? {
              dayName: mostActiveDay.dayName,
              completedSets: mostActiveDay.completedSets,
              percent: mostActiveDay.percent,
            }
          : null,
      },
      measurements: measurementChart,
      weeklyPerformance,
      monthlyPerformance,
      monthlySummary,
      dayPerformance,
      coachComments,
    });
  } catch (error) {
    console.error("GET CLIENT ANALYTICS ERROR:", error);
    res.status(500).json({
      message: "Analiz verileri alınamadı",
      error: error.message,
    });
  }
});

// Tüm antrenörleri getir
router.get("/trainers/all", async (req, res) => {
  try {
    const trainers = await prisma.trainerProfile.findMany({
      include: {
        user: true,
        workingHours: { orderBy: { id: "asc" } },
        appointments: {
          include: {
            client: { include: { user: true } },
          },
          orderBy: { createdAt: "desc" },
        },
      },
      orderBy: { id: "asc" },
    });

    const now = new Date();

    const dayNames = [
      "Pazar",
      "Pazartesi",
      "Salı",
      "Çarşamba",
      "Perşembe",
      "Cuma",
      "Cumartesi",
    ];

    const todayName = dayNames[now.getDay()];

    const trainersWithAvailability = trainers.map((trainer) => {
      const todayWorkingHour = trainer.workingHours.find(
        (item) => item.dayName === todayName && item.isAvailable === true
      );

      let availableNow = false;
      let statusLabel = "Çalışmıyor";
      let workingStart = null;
      let workingEnd = null;

      if (
        todayWorkingHour &&
        todayWorkingHour.startTime &&
        todayWorkingHour.endTime
      ) {
        workingStart = todayWorkingHour.startTime;
        workingEnd = todayWorkingHour.endTime;

        const currentMinutes = now.getHours() * 60 + now.getMinutes();

        const [startHour, startMinute] = todayWorkingHour.startTime
          .split(":")
          .map(Number);

        const [endHour, endMinute] = todayWorkingHour.endTime
          .split(":")
          .map(Number);

        const startMinutes = startHour * 60 + startMinute;
        const endMinutes = endHour * 60 + endMinute;

        availableNow =
          currentMinutes >= startMinutes && currentMinutes < endMinutes;
      }

      const todayAppointments = trainer.appointments.filter((appointment) => {
        const appointmentDate = new Date(appointment.date);

        return (
          appointmentDate.getDate() === now.getDate() &&
          appointmentDate.getMonth() === now.getMonth() &&
          appointmentDate.getFullYear() === now.getFullYear() &&
          appointment.status !== "CANCELLED"
        );
      });

      const todayAppointmentsCount = todayAppointments.length;
      const maxDailyAppointments = 3;
      const remainingAppointments =
        maxDailyAppointments - todayAppointmentsCount;

      const isFullyBooked = todayAppointmentsCount >= maxDailyAppointments;

      const activeAppointment = todayAppointments.find((appointment) => {
        if (appointment.status !== "APPROVED") return false;

        const [startHour, startMinute] = appointment.startTime
          .split(":")
          .map(Number);

        const [endHour, endMinute] = appointment.endTime.split(":").map(Number);

        const currentMinutes = now.getHours() * 60 + now.getMinutes();
        const startMinutes = startHour * 60 + startMinute;
        const endMinutes = endHour * 60 + endMinute;

        return currentMinutes >= startMinutes && currentMinutes < endMinutes;
      });

      if (!todayWorkingHour) {
        statusLabel = "Çalışmıyor";
      } else if (activeAppointment) {
        statusLabel = "Ders Veriyor";
      } else if (isFullyBooked) {
        statusLabel = "Dolu";
      } else if (availableNow) {
        statusLabel = "Uygun";
      } else {
        statusLabel = "Bugün Aktif";
      }

      return {
        ...trainer,
        availableNow,
        workingStart,
        workingEnd,
        todayAppointmentsCount,
        maxDailyAppointments,
        remainingAppointments,
        isFullyBooked,
        statusLabel,
      };
    });

    res.status(200).json(trainersWithAvailability);
  } catch (error) {
    console.error("GET TRAINERS ERROR:", error);
    res.status(500).json({
      message: "Antrenörler alınamadı",
      error: error.message,
    });
  }
});

// Tek antrenör profili getir
router.get("/trainers/:trainerId", async (req, res) => {
  try {
    const trainerId = Number(req.params.trainerId);

    const trainer = await prisma.trainerProfile.findUnique({
      where: { id: trainerId },
      include: {
        user: true,
        workingHours: { orderBy: { id: "asc" } },
        appointments: { orderBy: { createdAt: "desc" } },
      },
    });

    if (!trainer) {
      return res.status(404).json({ message: "Antrenör bulunamadı" });
    }

    res.status(200).json(trainer);
  } catch (error) {
    console.error("GET TRAINER PROFILE ERROR:", error);
    res.status(500).json({
      message: "Antrenör profili alınamadı",
      error: error.message,
    });
  }
});

// Randevu oluştur
router.post("/appointments", async (req, res) => {
  try {
    const { clientId, trainerId, date, startTime, endTime, note } = req.body;

    if (!clientId || !trainerId || !date || !startTime || !endTime) {
      return res.status(400).json({
        message: "clientId, trainerId, date, startTime ve endTime zorunlu",
      });
    }

    const appointmentDate = new Date(date);

    const [startHour, startMinute] = startTime.split(":").map(Number);
    const appointmentDateTime = new Date(appointmentDate);
    appointmentDateTime.setHours(startHour, startMinute, 0, 0);

    const now = new Date();

    if (appointmentDateTime <= now) {
      return res.status(400).json({
        message: "Geçmiş bir saate randevu alınamaz",
      });
    }

    const conflict = await prisma.appointment.findFirst({
      where: {
        trainerId: Number(trainerId),
        date: appointmentDate,
        status: { not: "CANCELLED" },
        OR: [
          { startTime },
          { endTime },
          {
            AND: [
              { startTime: { lt: endTime } },
              { endTime: { gt: startTime } },
            ],
          },
        ],
      },
    });

    if (conflict) {
      return res.status(400).json({
        message: "Bu saat için antrenörün zaten randevusu var",
      });
    }

    const startOfDay = new Date(
      appointmentDate.getFullYear(),
      appointmentDate.getMonth(),
      appointmentDate.getDate(),
      0,
      0,
      0
    );

    const endOfDay = new Date(
      appointmentDate.getFullYear(),
      appointmentDate.getMonth(),
      appointmentDate.getDate(),
      23,
      59,
      59
    );

    const dailyCount = await prisma.appointment.count({
      where: {
        trainerId: Number(trainerId),
        date: { gte: startOfDay, lte: endOfDay },
        status: { not: "CANCELLED" },
      },
    });

    if (dailyCount >= 3) {
      return res.status(400).json({
        message: "Bu antrenör bugün maksimum 3 özel ders alabilir",
      });
    }

    const appointment = await prisma.appointment.create({
      data: {
        clientId: Number(clientId),
        trainerId: Number(trainerId),
        date: appointmentDate,
        startTime,
        endTime,
        note: note || null,
        status: "PENDING",
      },
      include: {
        client: { include: { user: true } },
        trainer: { include: { user: true } },
      },
    });

    await prisma.notification.create({
      data: {
        userId: appointment.trainer.userId,
        title: "Yeni Özel Ders Talebi",
        message: `${appointment.client.user.fullName} senden ${startTime} - ${endTime} saatleri için özel ders talebinde bulundu.`,
        type: "APPOINTMENT",
      },
    });

    await prisma.notification.create({
      data: {
        userId: appointment.client.userId,
        title: "Özel Ders Talebi Oluşturuldu",
        message: `${appointment.trainer.user.fullName} adlı antrenöre özel ders talebin gönderildi. Onay bekleniyor.`,
        type: "APPOINTMENT",
      },
    });

    res.status(201).json({
      message: "Randevu oluşturuldu",
      appointment,
    });
  } catch (error) {
    console.error("CREATE APPOINTMENT ERROR:", error);
    res.status(500).json({
      message: "Randevu oluşturulamadı",
      error: error.message,
    });
  }
});

// Client antrenman gününü tamamlandı işaretler
router.post("/complete-workout", async (req, res) => {
  try {
    const { clientId, dayId } = req.body;

    if (!clientId || !dayId) {
      return res.status(400).json({
        message: "clientId ve dayId zorunlu",
      });
    }

    const completion = await prisma.workoutCompletion.upsert({
      where: {
        clientId_dayId: {
          clientId: Number(clientId),
          dayId: Number(dayId),
        },
      },
      update: { completedAt: new Date() },
      create: {
        clientId: Number(clientId),
        dayId: Number(dayId),
      },
    });

    res.status(201).json({
      message: "Antrenman tamamlandı",
      completion,
    });
  } catch (error) {
    console.error("COMPLETE WORKOUT ERROR:", error);
    res.status(500).json({
      message: "Antrenman tamamlanamadı",
      error: error.message,
    });
  }
});

// Client egzersizi tamamlandı işaretler / ağırlık kaydeder
router.post("/complete-exercise", async (req, res) => {
  try {
    const { clientId, exerciseId, isCompleted, weight } = req.body;

    if (!clientId || !exerciseId) {
      return res.status(400).json({
        message: "clientId ve exerciseId zorunlu",
      });
    }

    const completion = await prisma.exerciseCompletion.upsert({
      where: {
        clientId_exerciseId: {
          clientId: Number(clientId),
          exerciseId: Number(exerciseId),
        },
      },
      update: {
        isCompleted: typeof isCompleted === "boolean" ? isCompleted : true,
        weight:
          weight !== undefined && weight !== null && weight !== ""
            ? Number(weight)
            : null,
        completedAt: new Date(),
      },
      create: {
        clientId: Number(clientId),
        exerciseId: Number(exerciseId),
        isCompleted: typeof isCompleted === "boolean" ? isCompleted : true,
        weight:
          weight !== undefined && weight !== null && weight !== ""
            ? Number(weight)
            : null,
      },
    });

    res.status(201).json({
      message: "Egzersiz tamamlandı",
      completion,
    });
  } catch (error) {
    console.error("COMPLETE EXERCISE ERROR:", error);
    res.status(500).json({
      message: "Egzersiz tamamlanamadı",
      error: error.message,
    });
  }
});

// Client egzersiz setini tamamlandı işaretler / ağırlık kaydeder
router.post("/complete-set", async (req, res) => {
  try {
    const { clientId, exerciseId, setNumber, isCompleted, weight } = req.body;

    if (!clientId || !exerciseId || !setNumber) {
      return res.status(400).json({
        message: "clientId, exerciseId ve setNumber zorunlu",
      });
    }

    const completion = await prisma.exerciseSetCompletion.upsert({
      where: {
        clientId_exerciseId_setNumber: {
          clientId: Number(clientId),
          exerciseId: Number(exerciseId),
          setNumber: Number(setNumber),
        },
      },
      update: {
        isCompleted: typeof isCompleted === "boolean" ? isCompleted : true,
        weight:
          weight !== undefined && weight !== null && weight !== ""
            ? Number(weight)
            : null,
        completedAt: new Date(),
      },
      create: {
        clientId: Number(clientId),
        exerciseId: Number(exerciseId),
        setNumber: Number(setNumber),
        isCompleted: typeof isCompleted === "boolean" ? isCompleted : true,
        weight:
          weight !== undefined && weight !== null && weight !== ""
            ? Number(weight)
            : null,
      },
    });

    res.status(201).json({
      message: "Set güncellendi",
      completion,
    });
  } catch (error) {
    console.error("COMPLETE SET ERROR:", error);
    res.status(500).json({
      message: "Set tamamlanamadı",
      error: error.message,
    });
  }
});

// Uygun saatleri getir
router.get("/trainers/:trainerId/available-slots", async (req, res) => {
  try {
    const trainerId = Number(req.params.trainerId);
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({ message: "date zorunlu" });
    }

    const selectedDate = new Date(date);

    const dayNames = [
      "Pazar",
      "Pazartesi",
      "Salı",
      "Çarşamba",
      "Perşembe",
      "Cuma",
      "Cumartesi",
    ];

    const dayName = dayNames[selectedDate.getDay()];

    const workingHour = await prisma.trainerWorkingHour.findFirst({
      where: {
        trainerId,
        dayName,
        isAvailable: true,
      },
    });

    if (!workingHour || !workingHour.startTime || !workingHour.endTime) {
      return res.status(200).json([]);
    }

    const appointments = await prisma.appointment.findMany({
      where: {
        trainerId,
        date: selectedDate,
        status: { not: "CANCELLED" },
      },
    });

    const busyStarts = appointments.map((a) => a.startTime);

    const slots = [];
    const startHour = Number(workingHour.startTime.split(":")[0]);
    const endHour = Number(workingHour.endTime.split(":")[0]);

    const currentNow = new Date();

    for (let hour = startHour; hour < endHour; hour++) {
      const startTime = `${hour.toString().padStart(2, "0")}:00`;
      const endTime = `${(hour + 1).toString().padStart(2, "0")}:00`;

      const slotDateTime = new Date(selectedDate);
      slotDateTime.setHours(hour, 0, 0, 0);

      const isPast = slotDateTime <= currentNow;
      const isBusy = busyStarts.includes(startTime);

      if (!isPast && !isBusy) {
        slots.push({ startTime, endTime });
      }
    }

    res.status(200).json(slots);
  } catch (error) {
    console.error("GET AVAILABLE SLOTS ERROR:", error);
    res.status(500).json({
      message: "Uygun saatler alınamadı",
      error: error.message,
    });
  }
});

module.exports = router;