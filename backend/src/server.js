const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const cron = require("node-cron");

const programRoutes = require("./routes/program.routes");
const measurementRoutes = require("./routes/measurement.routes");
const workingHoursRoutes = require("./routes/working-hours.routes");
const clientRoutes = require("./routes/client.routes");
const notificationRoutes = require("./routes/notification.routes");
const aiRoutes = require("./routes/ai.routes");
const gymDensityRoutes = require("./routes/gym-density.routes");

dotenv.config();

const authRoutes = require("./routes/auth.routes");
const userRoutes = require("./routes/user.routes");
const trainerRoutes = require("./routes/trainer.routes");
const authMiddleware = require("./middleware/auth.middleware");

const prisma = require("./prisma");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Backend çalışıyor 🚀");
});

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/trainer", trainerRoutes);
app.use("/api/program", programRoutes);
app.use("/api/measurements", measurementRoutes);
app.use("/api/working-hours", workingHoursRoutes);
app.use("/api/client", clientRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/ai", aiRoutes);
app.use("/api/gym-density", gymDensityRoutes);

app.get("/api/profile", authMiddleware, (req, res) => {
  res.status(200).json({
    message: "Token geçerli",
    user: req.user,
  });
});

const motivationMessages = [
  "Bugün hedeflerine bir adım daha yaklaşmak için harika bir gün! 💪",
  "Disiplin motivasyondan daha güçlüdür. Devam et! 🔥",
  "Küçük ilerlemeler büyük sonuçlar getirir. 🚀",
  "Dünkü senden daha iyi olmak yeterli. ⭐",
  "Antrenmanını erteleme, gelecekteki sen sana teşekkür edecek. 🏋️",
  "Bugün vazgeçmezsen yarın daha güçlü olacaksın. 💥",
  "Başarı tekrar eden küçük alışkanlıkların sonucudur. 🎯",
  "Hedefine her set seni biraz daha yaklaştırıyor. 💯",
];

cron.schedule("0 9 * * *", async () => {
  try {
    console.log("📢 Günlük motivasyon bildirimi oluşturuluyor...");

    const users = await prisma.user.findMany({
      where: {
        role: {
          in: ["CLIENT", "TRAINER"],
        },
      },
    });

    for (const user of users) {
      const randomMessage =
        motivationMessages[
          Math.floor(Math.random() * motivationMessages.length)
        ];

      await prisma.notification.create({
        data: {
          userId: user.id,
          title: "Günün Motivasyonu 💪",
          message: randomMessage,
          type: "MOTIVATION",
        },
      });
    }

    console.log("✅ Motivasyon bildirimleri oluşturuldu");
  } catch (error) {
    console.error("CRON ERROR:", error);
  }
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server çalışıyor: http://localhost:${PORT}`);
});