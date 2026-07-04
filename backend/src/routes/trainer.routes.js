const express = require("express");
const prisma = require("../prisma");

const router = express.Router();

// Antrenörün kendi danışanlarını getir
router.get("/:trainerUserId/clients", async (req, res) => {
  try {
    const trainerUserId = parseInt(req.params.trainerUserId);

    const trainerProfile = await prisma.trainerProfile.findUnique({
      where: { userId: trainerUserId },
    });

    if (!trainerProfile) {
      return res.status(404).json({
        message: "Antrenör profili bulunamadı",
      });
    }

    const clients = await prisma.clientProfile.findMany({
      where: { trainerId: trainerProfile.id },
      include: {
        user: true,
        measurements: { orderBy: { createdAt: "desc" } },
        programs: {
          where: { isActive: true },
          include: {
            days: {
              include: {
                exercises: {
                  orderBy: { orderIndex: "asc" },
                },
              },
              orderBy: { id: "asc" },
            },
          },
          orderBy: { createdAt: "desc" },
        },
      },
      orderBy: { id: "asc" },
    });

    res.status(200).json(clients);
  } catch (error) {
    console.error("TRAINER CLIENTS ERROR:", error);
    res.status(500).json({
      message: "Danışanlar alınamadı",
      error: error.message,
    });
  }
});

// Antrenörün bugünkü randevuları
router.get("/:trainerUserId/appointments", async (req, res) => {
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

    const now = new Date();

    const startOfDay = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      0,
      0,
      0
    );

    const endOfDay = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      23,
      59,
      59
    );

    const appointments = await prisma.appointment.findMany({
      where: {
        trainerId: trainerProfile.id,
        date: {
          gte: startOfDay,
          lte: endOfDay,
        },
      },
      include: {
        client: { include: { user: true } },
      },
      orderBy: { startTime: "asc" },
    });

    const appointmentsWithTimeStatus = appointments.map((appointment) => {
      const [startHour, startMinute] = appointment.startTime
        .split(":")
        .map(Number);

      const appointmentDateTime = new Date(appointment.date);
      appointmentDateTime.setHours(startHour, startMinute, 0, 0);

      return {
        ...appointment,
        isPast: appointmentDateTime <= now,
      };
    });

    res.status(200).json(appointmentsWithTimeStatus);
  } catch (error) {
    console.error("TRAINER APPOINTMENTS ERROR:", error);
    res.status(500).json({
      message: "Randevular alınamadı",
      error: error.message,
    });
  }
});
// Trainer profile getir
router.get("/:trainerUserId/profile", async (req, res) => {
  try {
    const trainerUserId = Number(req.params.trainerUserId);

    const trainerProfile = await prisma.trainerProfile.findUnique({
      where: {
        userId: trainerUserId,
      },
      include: {
        user: true,
      },
    });

    if (!trainerProfile) {
      return res.status(404).json({
        message: "Trainer profili bulunamadı",
      });
    }

    return res.status(200).json(trainerProfile);
  } catch (error) {
    console.error("TRAINER PROFILE ERROR:", error);

    return res.status(500).json({
      message: "Trainer profili alınamadı",
      error: error.message,
    });
  }
});

// Randevu onayla / iptal et
router.put("/appointments/:appointmentId/status", async (req, res) => {
  try {
    const appointmentId = Number(req.params.appointmentId);
    const { status, cancelReason } = req.body;

    const allowedStatuses = ["APPROVED", "CANCELLED"];

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        message: "Geçersiz randevu durumu",
      });
    }

    const appointment = await prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        client: { include: { user: true } },
        trainer: { include: { user: true } },
      },
    });

    if (!appointment) {
      return res.status(404).json({
        message: "Randevu bulunamadı",
      });
    }

    const [startHour, startMinute] = appointment.startTime
      .split(":")
      .map(Number);

    const appointmentDateTime = new Date(appointment.date);
    appointmentDateTime.setHours(startHour, startMinute, 0, 0);

    const now = new Date();

    if (appointmentDateTime <= now && status === "APPROVED") {
      return res.status(400).json({
        message: "Geçmiş saatli randevu onaylanamaz",
      });
    }

    const finalCancelReason =
      status === "CANCELLED"
        ? cancelReason && cancelReason.trim() !== ""
          ? cancelReason.trim()
          : "Sebep belirtilmedi"
        : null;

    const updated = await prisma.appointment.update({
      where: { id: appointmentId },
      data: {
        status,
        cancelReason: finalCancelReason,
      },
      include: {
        client: { include: { user: true } },
        trainer: { include: { user: true } },
      },
    });

    if (status === "APPROVED") {
      await prisma.notification.create({
        data: {
          userId: updated.client.userId,
          title: "Özel Ders Onaylandı",
          message: `${updated.trainer.user.fullName} özel ders talebini onayladı. Saat: ${updated.startTime} - ${updated.endTime}`,
          type: "APPOINTMENT",
        },
      });
    }

    if (status === "CANCELLED") {
      await prisma.notification.create({
        data: {
          userId: updated.client.userId,
          title: "Özel Ders İptal Edildi",
          message: `${updated.trainer.user.fullName} özel ders talebini iptal etti. Sebep: ${finalCancelReason}`,
          type: "APPOINTMENT",
        },
      });
    }

    res.status(200).json({
      message: "Randevu durumu güncellendi",
      appointment: updated,
    });
  } catch (error) {
    console.error("UPDATE APPOINTMENT STATUS ERROR:", error);
    res.status(500).json({
      message: "Randevu durumu güncellenemedi",
      error: error.message,
    });
  }
});

module.exports = router;