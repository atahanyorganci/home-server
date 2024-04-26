import { LocalVolume } from "./docker";
import env from "./env";
import Jellyfin from "./media";

const tvHome = new LocalVolume("tv-home", env.TV_HOME);
const movieHome = new LocalVolume("movie-home", env.MOVIE_HOME);

const jellyfin = new Jellyfin("jellyfin", { volumes: { tvHome, movieHome }, env });

export const media = {
  dataPath: jellyfin.dataHome.driverOpts.apply(t => t?.device),
  containers: [jellyfin.container.name],
};
