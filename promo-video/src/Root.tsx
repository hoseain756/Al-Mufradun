import "./index.css";
import { Composition } from "remotion";
import { AlMufradunPromo } from "./AlMufradunPromo";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="AlMufradun-4K"
        component={AlMufradunPromo}
        durationInFrames={42 * 60}
        fps={60}
        width={3840}
        height={2160}
      />
      <Composition
        id="AlMufradun-Vertical-4K"
        component={AlMufradunPromo}
        durationInFrames={42 * 60}
        fps={60}
        width={2160}
        height={3840}
      />
      <Composition
        id="AlMufradun-Preview"
        component={AlMufradunPromo}
        durationInFrames={42 * 60}
        fps={60}
        width={1280}
        height={720}
      />
    </>
  );
};
