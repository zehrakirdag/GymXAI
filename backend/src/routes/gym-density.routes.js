const express = require("express");
const prisma = require("../prisma");

const router = express.Router();

const GYM_CAPACITY = 100;
const VALID_QR_CODE = "GYM_ACCESS_QR";

router.post("/scan", async (req, res) => {
  try {
    const { userId, qrCode } = req.body;

    if (!userId || !qrCode) {
      return res.status(400).json({
        message: "userId ve qrCode zorunludur",
      });
    }

    if (qrCode !== VALID_QR_CODE) {
      return res.status(400).json({
        message: "Geçersiz QR kod",
      });
    }

    const user = await prisma.user.findUnique({
      where: { id: Number(userId) },
      include: {
        clientProfile: true,
      },
    });

    if (!user || user.role !== "CLIENT") {
      return res.status(404).json({
        message: "Geçerli danışan bulunamadı",
      });
    }

    const lastLog = await prisma.gymEntryLog.findFirst({
      where: {
        userId: user.id,
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    const nextType = lastLog?.type === "ENTRY" ? "EXIT" : "ENTRY";

    const log = await prisma.gymEntryLog.create({
      data: {
        userId: user.id,
        type: nextType,
      },
    });

    return res.status(201).json({
      message:
        nextType === "ENTRY"
          ? "Salona giriş yapıldı"
          : "Salondan çıkış yapıldı",
      type: nextType,
      user: {
        id: user.id,
        fullName: user.fullName,
        gender: user.clientProfile?.gender,
      },
      log,
    });
  } catch (error) {
    console.error("GYM QR SCAN ERROR:", error);
    return res.status(500).json({
      message: "QR işlemi yapılamadı",
      error: error.message,
    });
  }
});

router.get("/status", async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      where: {
        role: "CLIENT",
      },
      include: {
        clientProfile: true,
        gymEntryLogs: {
          orderBy: {
            createdAt: "desc",
          },
          take: 1,
        },
      },
    });

    const insideUsers = users.filter((user) => {
      const lastLog = user.gymEntryLogs[0];
      return lastLog && lastLog.type === "ENTRY";
    });

    const currentCount = insideUsers.length;

    const femaleCount = insideUsers.filter((user) => {
      const gender = user.clientProfile?.gender?.toString().toLowerCase() ?? "";
      return gender.includes("kadın") || gender.includes("kadin") || gender.includes("female");
    }).length;

    const maleCount = insideUsers.filter((user) => {
      const gender = user.clientProfile?.gender?.toString().toLowerCase() ?? "";
      return gender.includes("erkek") || gender.includes("male");
    }).length;

    const densityPercent = Math.min(
      100,
      Math.round((currentCount / GYM_CAPACITY) * 100)
    );

    const femalePercent =
      currentCount === 0 ? 0 : Math.round((femaleCount / currentCount) * 100);

    const malePercent =
      currentCount === 0 ? 0 : Math.round((maleCount / currentCount) * 100);

    return res.status(200).json({
      capacity: GYM_CAPACITY,
      currentCount,
      densityPercent,
      femaleCount,
      maleCount,
      femalePercent,
      malePercent,
    });
  } catch (error) {
    console.error("GYM STATUS ERROR:", error);
    return res.status(500).json({
      message: "Salon yoğunluğu alınamadı",
      error: error.message,
    });
  }
});

module.exports = router;