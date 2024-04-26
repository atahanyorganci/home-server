import { z } from "zod";

const envSchema = z.object({
  TZ: z.string(),
  PUID: z.string(),
  PGID: z.string(),
  TV_HOME: z.string(),
  MOVIE_HOME: z.string(),
  DATA_HOME: z.string(),
  DOMAIN: z.string(),
  CLOUDFLARE_ACCOUNT_ID: z.string(),
  CLOUDFLARE_ZONE_ID: z.string(),
});

export type Env = z.infer<typeof envSchema>;

export default envSchema.parse(process.env);
