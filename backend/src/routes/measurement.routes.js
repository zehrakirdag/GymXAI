const express = require("express");
const prisma = require("../prisma");

const router = express.Router();

// Ölçüm ekle
router.post("/create", async (req, res) => {
  try {
    const {
      clientId,
      weight,
      bodyFat,
      height,
      bmi,
      waist,
      hip,
      shoulder,
      arm,
      leg,
      calf,
      note,
    } = req.body;

    if (!clientId || !weight) {
      return res.status(400).json({
        message: "clientId ve kilo zorunlu",
      });
    }

    const measurement = await prisma.measurement.create({
      data: {
        clientId: Number(clientId),
        weight: Number(weight),
        bodyFat: bodyFat ? Number(bodyFat) : null,
        height: height ? Number(height) : null,
        bmi: bmi ? Number(bmi) : null,
        waist: waist ? Number(waist) : null,
        hip: hip ? Number(hip) : null,
        shoulder: shoulder ? Number(shoulder) : null,
        arm: arm ? Number(arm) : null,
        leg: leg ? Number(leg) : null,
        calf: calf ? Number(calf) : null,
        note: note || null,
      },
    });

    res.status(201).json({
      message: "Ölçüm eklendi",
      measurement,
    });
  } catch (error) {
    console.error("CREATE MEASUREMENT ERROR:", error);
    res.status(500).json({
      message: "Ölçüm eklenemedi",
      error: error.message,
    });
  }
});

// Danışanın ölçümlerini getir
router.get("/client/:clientId", async (req, res) => {
  try {
    const clientId = Number(req.params.clientId);

    const measurements = await prisma.measurement.findMany({
      where: {
        clientId,
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    res.status(200).json(measurements);
  } catch (error) {
    console.error("GET MEASUREMENTS ERROR:", error);
    res.status(500).json({
      message: "Ölçümler alınamadı",
      error: error.message,
    });
  }
});

module.exports = router;