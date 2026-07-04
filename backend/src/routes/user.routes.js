const express = require("express");
const bcrypt = require("bcrypt");
const prisma = require("../prisma");

const router = express.Router();

// =========================
// USER CREATE
// =========================
router.post("/create", async (req, res) => {
  try {
    const {
      fullName,
      email,
      password,
      role,
      phone,

      gender,
      birthDate,
      height,
      startWeight,
      targetWeight,
      goal,
      activityLevel,
      healthNotes,
      injuryNotes,

      specialty,
      bio,
      isAvailable,
    } = req.body;

    if (!fullName || !email || !password || !role) {
      return res.status(400).json({
        message: "fullName, email, password ve role zorunlu",
      });
    }

    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      return res.status(409).json({
        message: "Bu email zaten kayıtlı",
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    let createdUser;

    if (role === "CLIENT") {
      createdUser = await prisma.user.create({
        data: {
          fullName,
          email,
          password: hashedPassword,
          role,
          phone: phone || null,
          isActive: true,
          clientProfile: {
            create: {
              gender: gender || null,
              birthDate: birthDate ? new Date(birthDate) : null,
              height: height ? Number(height) : null,
              startWeight: startWeight ? Number(startWeight) : null,
              targetWeight: targetWeight ? Number(targetWeight) : null,
              goal: goal || null,
              activityLevel: activityLevel || null,
              healthNotes: healthNotes || null,
              injuryNotes: injuryNotes || null,
            },
          },
        },
        include: {
          clientProfile: true,
        },
      });
    } else if (role === "TRAINER") {
      createdUser = await prisma.user.create({
        data: {
          fullName,
          email,
          password: hashedPassword,
          role,
          phone: phone || null,
          isActive: true,
          trainerProfile: {
            create: {
              specialty: specialty || null,
              bio: bio || null,
              isAvailable:
                typeof isAvailable === "boolean" ? isAvailable : true,
            },
          },
        },
        include: {
          trainerProfile: true,
        },
      });
    } else {
      createdUser = await prisma.user.create({
        data: {
          fullName,
          email,
          password: hashedPassword,
          role,
          phone: phone || null,
          isActive: true,
        },
      });
    }

    res.status(201).json({
      message: "Kullanıcı oluşturuldu",
      user: createdUser,
    });
  } catch (error) {
    console.error("CREATE USER ERROR:", error);
    res.status(500).json({
      message: "Sunucu hatası",
      error: error.message,
    });
  }
});

// =========================
// CLIENT LIST
// =========================
router.get("/clients", async (req, res) => {
  try {
    const clients = await prisma.user.findMany({
      where: { role: "CLIENT" },
      include: {
        clientProfile: {
          include: {
            trainer: {
              include: {
                user: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    res.status(200).json(clients);
  } catch (error) {
    console.error("GET CLIENTS ERROR:", error);
    res.status(500).json({
      message: "Sunucu hatası",
      error: error.message,
    });
  }
});

// =========================
// CLIENT UPDATE
// =========================
router.put("/:id", async (req, res) => {
  try {
    const userId = parseInt(req.params.id);

    const {
      fullName,
      email,
      phone,
      gender,
      birthDate,
      height,
      startWeight,
      targetWeight,
      goal,
      activityLevel,
      healthNotes,
      injuryNotes,
    } = req.body;

    const existingUser = await prisma.user.findUnique({
      where: { id: userId },
      include: { clientProfile: true },
    });

    if (!existingUser) {
      return res.status(404).json({
        message: "Kullanıcı bulunamadı",
      });
    }

    const clientProfileData = {
      gender: gender || null,
      birthDate: birthDate ? new Date(birthDate) : null,
      height: height ? Number(height) : null,
      startWeight: startWeight ? Number(startWeight) : null,
      targetWeight: targetWeight ? Number(targetWeight) : null,
      goal: goal || null,
      activityLevel: activityLevel || null,
      healthNotes: healthNotes || null,
      injuryNotes: injuryNotes || null,
    };

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        fullName,
        email,
        phone,
        clientProfile: existingUser.clientProfile
          ? {
              update: clientProfileData,
            }
          : {
              create: clientProfileData,
            },
      },
      include: {
        clientProfile: true,
      },
    });

    res.status(200).json(updatedUser);
  } catch (error) {
    console.error("UPDATE USER ERROR:", error);
    res.status(500).json({
      message: "Güncelleme hatası",
      error: error.message,
    });
  }
});

// =========================
// TRAINER LIST
// =========================
router.get("/trainers", async (req, res) => {
  try {
    const trainers = await prisma.user.findMany({
      where: { role: "TRAINER" },
      include: { trainerProfile: true },
      orderBy: { createdAt: "desc" },
    });

    res.status(200).json(trainers);
  } catch (error) {
    console.error("GET TRAINERS ERROR:", error);
    res.status(500).json({
      message: "Sunucu hatası",
      error: error.message,
    });
  }
});

// =========================
// TRAINER UPDATE
// =========================
router.put("/trainer/:id", async (req, res) => {
  try {
    const userId = parseInt(req.params.id);

    const { fullName, email, phone, specialty, bio, isAvailable } = req.body;

    const existingTrainer = await prisma.user.findUnique({
      where: { id: userId },
      include: { trainerProfile: true },
    });

    if (!existingTrainer) {
      return res.status(404).json({
        message: "Antrenör bulunamadı",
      });
    }

    const updatedTrainer = await prisma.user.update({
      where: { id: userId },
      data: {
        fullName,
        email,
        phone,
        trainerProfile: existingTrainer.trainerProfile
          ? {
              update: { specialty, bio, isAvailable },
            }
          : {
              create: {
                specialty: specialty || null,
                bio: bio || null,
                isAvailable:
                  typeof isAvailable === "boolean" ? isAvailable : true,
              },
            },
      },
      include: { trainerProfile: true },
    });

    res.status(200).json(updatedTrainer);
  } catch (error) {
    console.error("UPDATE TRAINER ERROR:", error);
    res.status(500).json({
      message: "Antrenör güncellenemedi",
      error: error.message,
    });
  }
});

// =========================
// TRAINER DELETE
// =========================
router.delete("/trainer/:id", async (req, res) => {
  try {
    const userId = parseInt(req.params.id);

    await prisma.user.delete({
      where: { id: userId },
    });

    res.status(200).json({
      message: "Antrenör silindi",
    });
  } catch (error) {
    console.error("DELETE TRAINER ERROR:", error);
    res.status(500).json({
      message: "Antrenör silinemedi",
      error: error.message,
    });
  }
});

// =========================
// ASSIGN TRAINER
// =========================
router.put("/assign-trainer/:clientId", async (req, res) => {
  try {
    const clientId = parseInt(req.params.clientId);
    const { trainerId } = req.body;

    const existingUser = await prisma.user.findUnique({
      where: { id: clientId },
      include: {
        clientProfile: true,
      },
    });

    if (!existingUser) {
      return res.status(404).json({
        message: "Danışan bulunamadı",
      });
    }

    if (existingUser.role !== "CLIENT") {
      return res.status(400).json({
        message: "Bu kullanıcı danışan değil",
      });
    }

    let updatedClient;

    if (existingUser.clientProfile) {
      updatedClient = await prisma.clientProfile.update({
        where: {
          userId: clientId,
        },
        data: {
          trainerId: trainerId || null,
        },
        include: {
          trainer: {
            include: {
              user: true,
            },
          },
        },
      });
    } else {
      updatedClient = await prisma.clientProfile.create({
        data: {
          userId: clientId,
          trainerId: trainerId || null,
        },
        include: {
          trainer: {
            include: {
              user: true,
            },
          },
        },
      });
    }

    res.status(200).json(updatedClient);
  } catch (error) {
    console.error("ASSIGN TRAINER ERROR:", error);
    res.status(500).json({
      message: "Antrenör atama hatası",
      error: error.message,
    });
  }
});

module.exports = router;