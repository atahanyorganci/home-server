import { z } from "zod";

const envSchema = z.object({
  TZ: z.string(),
  PUID: z.string(),
  PGID: z.string(),
  TV_HOME: z.string(),
  MOVIE_HOME: z.string(),
  DATA_HOME: z.string(),
});

export type Env = z.infer<typeof envSchema>;

export default envSchema.parse(process.env);
