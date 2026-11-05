import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { initDb, db } from './src/server/db.js';
import { seedInitialData } from './src/server/seed.js';
import { apiRouter } from './src/server/api.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const isProduction = process.env.NODE_ENV === 'production';
const PORT = parseInt(process.env.PORT || '3000', 10);

async function startServer() {
  const app = express();

  // Middleware: Support large spreadsheets, data analytics imports, and backups
  app.use(express.json({ limit: '100mb' }));
  app.use(express.urlencoded({ extended: true, limit: '100mb' }));

  // Initialize MySQL schema; demo data is opt-in.
  try {
    (await initDb());
    if (process.env.SEED_DEMO_DATA === 'true') await seedInitialData();
  } catch (err) {
    console.error('CRITICAL: Failed to initialize database or run migrations:', err);
    process.exit(1);
  }

  // Mount API Router
  app.use('/api', apiRouter);

  // Health check endpoint
  app.get('/api/health', async (_req, res) => {
    try { await db.query('SELECT 1'); res.json({ status: 'ok', database: 'mysql', timestamp: new Date().toISOString() }); }
    catch { res.status(503).json({ status: 'error', database: 'mysql' }); }
  });

  // Global Error Handler (handles PayloadTooLargeError cleanly)
  app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
    if (err && (err.type === 'entity.too.large' || err.status === 413)) {
      return res.status(413).json({
        error: 'حجم الملف أو الطلب كبير جداً ويتجاوز الحد الأقصى المسموح به (100 ميجابايت). يرجى تقليص حجم الملف أو تقسيمه.',
        code: 'PAYLOAD_TOO_LARGE'
      });
    }
    if (err) {
      console.error('Unhandled server error:', err);
      return res.status(err.status || 500).json({
        error: err.message || 'حدث خطأ غير متوقع في الخادم.',
        code: err.code || 'INTERNAL_SERVER_ERROR'
      });
    }
    next();
  });

  if (!isProduction) {
    // Development mode: Mount Vite middlewares
    const { createServer: createViteServer } = await import('vite');
    const vite = await createViteServer({
      server: {
        middlewareMode: true,
        host: '0.0.0.0',
        port: PORT,
        hmr: false
      },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    // Production mode: Serve built static files
    const distPath = path.resolve(__dirname, 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.resolve(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Al-Mizan ERP Server running on http://0.0.0.0:${PORT}`);
  });
}

startServer().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
