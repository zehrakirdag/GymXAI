const express = require("express");
const prisma = require("../prisma");

const router = express.Router();

//
// Kullanıcının tüm bildirimleri
//
router.get("/:userId", async (req, res) => {
  try {
    const userId = Number(req.params.userId);

    const notifications = await prisma.notification.findMany({
      where: {
        userId,
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    res.status(200).json(notifications);
  } catch (error) {
    console.error("GET NOTIFICATIONS ERROR:", error);

    res.status(500).json({
      message: "Bildirimler alınamadı",
      error: error.message,
    });
  }
});

//
// Tek bildirimi okundu yap
//
router.put("/:notificationId/read", async (req, res) => {
  try {
    const notificationId = Number(req.params.notificationId);

    const notification = await prisma.notification.update({
      where: {
        id: notificationId,
      },
      data: {
        isRead: true,
      },
    });

    res.status(200).json({
      message: "Bildirim okundu",
      notification,
    });
  } catch (error) {
    console.error("READ NOTIFICATION ERROR:", error);

    res.status(500).json({
      message: "Bildirim güncellenemedi",
      error: error.message,
    });
  }
});

//
// Tüm bildirimleri okundu yap
//
router.put("/:userId/read-all", async (req, res) => {
  try {
    const userId = Number(req.params.userId);

    await prisma.notification.updateMany({
      where: {
        userId,
        isRead: false,
      },
      data: {
        isRead: true,
      },
    });

    res.status(200).json({
      message: "Tüm bildirimler okundu",
    });
  } catch (error) {
    console.error("READ ALL NOTIFICATIONS ERROR:", error);

    res.status(500).json({
      message: "Bildirimler güncellenemedi",
      error: error.message,
    });
  }
});

//
// Günlük motivasyon bildirimi
//
router.post("/motivation/daily", async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      where: {
        role: {
          in: ["CLIENT", "TRAINER"],
        },
      },
    });

    for (const user of users) {
      await prisma.notification.create({
        data: {
          userId: user.id,
          title: "Günün Motivasyonu 💪",
          message:
            "Bugün hedeflerine bir adım daha yaklaşmak için harika bir gün. Vazgeçme!",
          type: "MOTIVATION",
        },
      });
    }

    res.status(200).json({
      message: "Motivasyon bildirimleri oluşturuldu",
    });
  } catch (error) {
    console.error("DAILY MOTIVATION ERROR:", error);

    res.status(500).json({
      message: "Motivasyon bildirimi oluşturulamadı",
      error: error.message,
    });
  }
});

module.exports = router;