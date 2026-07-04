const express = require("express");
const prisma = require("../prisma");

const router = express.Router();

// PROGRAM CREATE
router.post("/create", async (req, res) => {
  try {
    const { clientId, title, description, startDate, days } = req.body;

    if (!clientId || !title) {
      return res.status(400).json({ message: "clientId ve title zorunlu" });
    }

    const clientProfile = await prisma.clientProfile.findUnique({
      where: { id: Number(clientId) },
    });

    if (!clientProfile) {
      return res.status(404).json({ message: "Danışan profili bulunamadı" });
    }

    const program = await prisma.workoutProgram.create({
      data: {
        clientId: Number(clientId),
        title,
        description: description || null,
        startDate: startDate ? new Date(startDate) : null,
        days: {
          create: Array.isArray(days)
            ? days.map((day) => ({
                dayName: day.dayName,
                focus: day.focus || null,
                note: day.note || null,
                exercises: {
                  create: Array.isArray(day.exercises)
                    ? day.exercises.map((exercise, index) => ({
                        name: exercise.name,
                        sets: exercise.sets ? Number(exercise.sets) : null,
                        reps: exercise.reps ? Number(exercise.reps) : null,
                        duration: exercise.duration || null,
                        description: exercise.description || null,
                        status: exercise.status || "PLANNED",
                        orderIndex:
                          typeof exercise.orderIndex === "number"
                            ? exercise.orderIndex
                            : index,
                      }))
                    : [],
                },
              }))
            : [],
        },
      },
      include: {
        days: {
          include: {
            exercises: { orderBy: { orderIndex: "asc" } },
          },
          orderBy: { id: "asc" },
        },
      },
    });

    res.status(201).json({
      message: "Program oluşturuldu",
      program,
    });
  } catch (error) {
    console.error("CREATE PROGRAM ERROR:", error);
    res.status(500).json({
      message: "Program oluşturulamadı",
      error: error.message,
    });
  }
});

// CLIENT PROGRAM LIST
router.get("/client/:clientId", async (req, res) => {
  try {
    const clientId = Number(req.params.clientId);

    const programs = await prisma.workoutProgram.findMany({
      where: {
        clientId,
        isActive: true,
      },
      include: {
        days: {
          include: {
            exercises: { orderBy: { orderIndex: "asc" } },
          },
          orderBy: { id: "asc" },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    res.status(200).json(programs);
  } catch (error) {
    console.error("GET CLIENT PROGRAMS ERROR:", error);
    res.status(500).json({
      message: "Programlar alınamadı",
      error: error.message,
    });
  }
});

// PROGRAM FULL UPDATE
router.put("/:programId/full-update", async (req, res) => {
  try {
    const programId = Number(req.params.programId);
    const { title, description, startDate, days } = req.body;

    const existingProgram = await prisma.workoutProgram.findUnique({
      where: { id: programId },
      include: {
        days: {
          include: {
            exercises: true,
          },
        },
      },
    });

    if (!existingProgram) {
      return res.status(404).json({
        message: "Program bulunamadı",
      });
    }

    for (const day of existingProgram.days) {
      await prisma.workoutExercise.deleteMany({
        where: { dayId: day.id },
      });
    }

    await prisma.workoutDay.deleteMany({
      where: { programId },
    });

    const updatedProgram = await prisma.workoutProgram.update({
      where: { id: programId },
      data: {
        title,
        description: description || null,
        startDate: startDate ? new Date(startDate) : null,
        days: {
          create: Array.isArray(days)
            ? days.map((day) => ({
                dayName: day.dayName,
                focus: day.focus || null,
                note: day.note || null,
                exercises: {
                  create: Array.isArray(day.exercises)
                    ? day.exercises.map((exercise, index) => ({
                        name: exercise.name,
                        sets: exercise.sets ? Number(exercise.sets) : null,
                        reps: exercise.reps ? Number(exercise.reps) : null,
                        duration: exercise.duration || null,
                        description: exercise.description || null,
                        status: exercise.status || "PLANNED",
                        orderIndex:
                          typeof exercise.orderIndex === "number"
                            ? exercise.orderIndex
                            : index,
                      }))
                    : [],
                },
              }))
            : [],
        },
      },
      include: {
        days: {
          include: {
            exercises: { orderBy: { orderIndex: "asc" } },
          },
          orderBy: { id: "asc" },
        },
      },
    });

    res.status(200).json({
      message: "Program güncellendi",
      program: updatedProgram,
    });
  } catch (error) {
    console.error("FULL UPDATE PROGRAM ERROR:", error);
    res.status(500).json({
      message: "Program güncellenemedi",
      error: error.message,
    });
  }
});

// PROGRAM DETAIL
router.get("/:programId", async (req, res) => {
  try {
    const programId = Number(req.params.programId);

    const program = await prisma.workoutProgram.findUnique({
      where: { id: programId },
      include: {
        client: {
          include: { user: true },
        },
        days: {
          include: {
            exercises: { orderBy: { orderIndex: "asc" } },
          },
          orderBy: { id: "asc" },
        },
      },
    });

    if (!program) {
      return res.status(404).json({ message: "Program bulunamadı" });
    }

    res.status(200).json(program);
  } catch (error) {
    console.error("GET PROGRAM DETAIL ERROR:", error);
    res.status(500).json({
      message: "Program detayı alınamadı",
      error: error.message,
    });
  }
});

// PROGRAM DEACTIVATE
router.patch("/:programId/deactivate", async (req, res) => {
  try {
    const programId = Number(req.params.programId);

    const program = await prisma.workoutProgram.update({
      where: { id: programId },
      data: { isActive: false },
    });

    res.status(200).json({
      message: "Program pasife alındı",
      program,
    });
  } catch (error) {
    console.error("DEACTIVATE PROGRAM ERROR:", error);
    res.status(500).json({
      message: "Program pasife alınamadı",
      error: error.message,
    });
  }
});

// DAY UPDATE
router.put("/day/:dayId", async (req, res) => {
  try {
    const dayId = Number(req.params.dayId);
    const { dayName, focus, note } = req.body;

    const day = await prisma.workoutDay.update({
      where: { id: dayId },
      data: { dayName, focus, note },
      include: {
        exercises: { orderBy: { orderIndex: "asc" } },
      },
    });

    res.status(200).json(day);
  } catch (error) {
    console.error("UPDATE DAY ERROR:", error);
    res.status(500).json({
      message: "Gün güncellenemedi",
      error: error.message,
    });
  }
});

// EXERCISE ADD
router.post("/day/:dayId/exercise", async (req, res) => {
  try {
    const dayId = Number(req.params.dayId);
    const { name, sets, reps, duration, description, status, orderIndex } =
      req.body;

    if (!name) {
      return res.status(400).json({ message: "Egzersiz adı zorunlu" });
    }

    const exercise = await prisma.workoutExercise.create({
      data: {
        dayId,
        name,
        sets: sets ? Number(sets) : null,
        reps: reps ? Number(reps) : null,
        duration: duration || null,
        description: description || null,
        status: status || "PLANNED",
        orderIndex: typeof orderIndex === "number" ? orderIndex : 0,
      },
    });

    res.status(201).json({
      message: "Egzersiz eklendi",
      exercise,
    });
  } catch (error) {
    console.error("ADD EXERCISE ERROR:", error);
    res.status(500).json({
      message: "Egzersiz eklenemedi",
      error: error.message,
    });
  }
});

// EXERCISE UPDATE
router.put("/exercise/:exerciseId", async (req, res) => {
  try {
    const exerciseId = Number(req.params.exerciseId);
    const { name, sets, reps, duration, description, status, orderIndex } =
      req.body;

    const exercise = await prisma.workoutExercise.update({
      where: { id: exerciseId },
      data: {
        name,
        sets: sets !== undefined ? Number(sets) : undefined,
        reps: reps !== undefined ? Number(reps) : undefined,
        duration,
        description,
        status,
        orderIndex: orderIndex !== undefined ? Number(orderIndex) : undefined,
      },
    });

    res.status(200).json(exercise);
  } catch (error) {
    console.error("UPDATE EXERCISE ERROR:", error);
    res.status(500).json({
      message: "Egzersiz güncellenemedi",
      error: error.message,
    });
  }
});

// EXERCISE DELETE
router.delete("/exercise/:exerciseId", async (req, res) => {
  try {
    const exerciseId = Number(req.params.exerciseId);

    await prisma.workoutExercise.delete({
      where: { id: exerciseId },
    });

    res.status(200).json({ message: "Egzersiz silindi" });
  } catch (error) {
    console.error("DELETE EXERCISE ERROR:", error);
    res.status(500).json({
      message: "Egzersiz silinemedi",
      error: error.message,
    });
  }
});

module.exports = router;