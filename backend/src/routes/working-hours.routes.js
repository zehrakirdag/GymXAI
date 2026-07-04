const express = require("express");
const prisma = require("../prisma");

const router = express.Router();

// Trainer çalışma saatlerini getir
router.get("/:trainerUserId", async (req, res) => {
  try {
    const trainerUserId = Number(req.params.trainerUserId);

    const trainerProfile = await prisma.trainerProfile.findUnique({
      where: { userId: trainerUserId },
    });

    if (!trainerProfile) {
      return res.status(404).json({
        message: "Antrenör profili bulunamadı",
      });
    }

    let workingHours = await prisma.trainerWorkingHour.findMany({
      where: { trainerId: trainerProfile.id },
      include: {
        specialLessons: {
          include: {
            client: {
              include: {
                user: true,
              },
            },
          },
          orderBy: {
            startTime: "asc",
          },
        },
      },
      orderBy: { id: "asc" },
    });

    if (workingHours.length === 0) {
      const defaultDays = [
        "Pazartesi",
        "Salı",
        "Çarşamba",
        "Perşembe",
        "Cuma",
        "Cumartesi",
        "Pazar",
      ];

      await prisma.trainerWorkingHour.createMany({
        data: defaultDays.map((dayName) => ({
          trainerId: trainerProfile.id,
          dayName,
          isAvailable: false,
          startTime: null,
          endTime: null,
          note: "İzin günü",
        })),
      });

      workingHours = await prisma.trainerWorkingHour.findMany({
        where: { trainerId: trainerProfile.id },
        include: {
          specialLessons: {
            include: {
              client: {
                include: {
                  user: true,
                },
              },
            },
            orderBy: {
              startTime: "asc",
            },
          },
        },
        orderBy: { id: "asc" },
      });
    }

    res.status(200).json(workingHours);
  } catch (error) {
    console.error("GET WORKING HOURS ERROR:", error);
    res.status(500).json({
      message: "Çalışma saatleri alınamadı",
      error: error.message,
    });
  }
});

// Tek gün güncelle
router.put("/:workingHourId", async (req, res) => {
  try {
    const workingHourId = Number(req.params.workingHourId);
    const { isAvailable, startTime, endTime, note } = req.body;

    const updated = await prisma.trainerWorkingHour.update({
      where: { id: workingHourId },
      data: {
        isAvailable,
        startTime: isAvailable ? startTime : null,
        endTime: isAvailable ? endTime : null,
        note: note || null,
      },
      include: {
        specialLessons: {
          include: {
            client: {
              include: {
                user: true,
              },
            },
          },
          orderBy: {
            startTime: "asc",
          },
        },
      },
    });

    res.status(200).json({
      message: "Çalışma saati güncellendi",
      workingHour: updated,
    });
  } catch (error) {
    console.error("UPDATE WORKING HOUR ERROR:", error);
    res.status(500).json({
      message: "Çalışma saati güncellenemedi",
      error: error.message,
    });
  }
});

// Özel ders ekle
router.post("/:workingHourId/special-lessons", async (req, res) => {
  try {
    const workingHourId = Number(req.params.workingHourId);
    const { clientId, startTime, endTime } = req.body;

    if (!startTime || !endTime) {
      return res.status(400).json({
        message: "startTime ve endTime zorunlu",
      });
    }

    const workingHour = await prisma.trainerWorkingHour.findUnique({
      where: { id: workingHourId },
    });

    if (!workingHour) {
      return res.status(404).json({
        message: "Çalışma günü bulunamadı",
      });
    }

    const lesson = await prisma.trainerSpecialLesson.create({
      data: {
        workingHourId,
        clientId: clientId ? Number(clientId) : null,
        startTime,
        endTime,
      },
      include: {
        client: {
          include: {
            user: true,
          },
        },
      },
    });

    res.status(201).json({
      message: "Özel ders eklendi",
      lesson,
    });
  } catch (error) {
    console.error("CREATE SPECIAL LESSON ERROR:", error);
    res.status(500).json({
      message: "Özel ders eklenemedi",
      error: error.message,
    });
  }
});

// Özel ders sil
router.delete("/special-lessons/:lessonId", async (req, res) => {
  try {
    const lessonId = Number(req.params.lessonId);

    await prisma.trainerSpecialLesson.delete({
      where: { id: lessonId },
    });

    res.status(200).json({
      message: "Özel ders silindi",
    });
  } catch (error) {
    console.error("DELETE SPECIAL LESSON ERROR:", error);
    res.status(500).json({
      message: "Özel ders silinemedi",
      error: error.message,
    });
  }
});

module.exports = router;