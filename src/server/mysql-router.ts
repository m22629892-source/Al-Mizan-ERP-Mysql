import express, { RequestHandler } from 'express';
import { db } from './mysql-database.js';

/** Express 4 does not catch rejected promises. Buffer write responses until COMMIT. */
export function Router() {
  const router = express.Router();
  for (const method of ['get', 'post', 'put', 'patch', 'delete'] as const) {
    const register = (router[method] as any).bind(router);
    (router as any)[method] = (route: any, ...handlers: RequestHandler[]) => register(route, ...handlers.map((handler, index) => {
      return (req: any, res: any, next: any) => {
        if (method === 'get' || index !== handlers.length - 1) {
          Promise.resolve().then(() => handler(req, res, next)).catch(next); return;
        }
        const originalJson = res.json;
        let payload: any, buffered = false;
        const rejection = new Error('HTTP_TRANSACTION_ROLLBACK');
        res.json = function(body: any) { payload = body; buffered = true; return this; };
        db.transaction(async () => {
          await handler(req, res, next);
          if (res.statusCode >= 400 && route !== '/auth/login') throw rejection;
        })().then(() => {
          res.json = originalJson;
          if (buffered) res.json(payload);
        }).catch((error: any) => {
          res.json = originalJson;
          if (error === rejection && buffered) res.json(payload);
          else next(error);
        });
      };
    }));
  }
  return router;
}
