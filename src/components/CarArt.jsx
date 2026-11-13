// Flat side-view car illustrations, one silhouette per vehicle type.
// Color is derived from the car id so each listing looks distinct.
const PALETTE = ["#e8590c", "#1c7ed6", "#2b8a3e", "#5f3dc4", "#c92a2a", "#0b7285", "#e67700", "#495057"];

const BODIES = {
  sedan: "M18 62 L30 44 Q36 36 48 36 L104 36 Q116 36 124 44 L140 56 L168 60 Q178 62 178 72 L178 80 L14 80 L14 70 Q14 64 18 62 Z",
  suv: "M16 58 L26 34 Q30 26 40 26 L120 26 Q130 26 136 34 L150 52 L170 56 Q180 58 180 70 L180 80 L12 80 L12 66 Q12 60 16 58 Z",
  truck: "M14 56 L24 32 Q28 26 36 26 L84 26 Q92 26 94 34 L98 52 L180 52 Q184 52 184 58 L184 80 L10 80 L10 62 Q10 58 14 56 Z",
  ev: "M16 64 Q30 36 64 32 L112 32 Q146 34 164 56 Q180 60 180 72 L180 80 L12 80 L12 72 Q12 66 16 64 Z",
};
const WINDOWS = {
  sedan: "M40 46 L50 40 L78 40 L78 54 L34 54 Z M84 40 L102 40 Q112 40 118 46 L124 54 L84 54 Z",
  suv: "M32 54 L38 32 L74 32 L74 52 Z M80 32 L118 32 Q126 32 130 38 L140 52 L80 52 Z",
  truck: "M30 50 L36 32 L86 32 L90 50 Z",
  ev: "M44 54 Q54 38 76 38 L76 54 Z M82 38 L110 38 Q132 40 146 54 L82 54 Z",
};

export default function CarArt({ type = "", id = 0, className = "" }) {
  const key = String(type).toLowerCase();
  const kind = BODIES[key] ? key : "sedan";
  const color = PALETTE[Math.abs(Number(id) || 0) % PALETTE.length];
  return (
    <svg className={`car-art ${className}`} viewBox="0 0 192 100" role="img" aria-label={`${type || "Car"} illustration`}>
      <ellipse cx="96" cy="90" rx="84" ry="5" fill="rgba(0,0,0,.12)" />
      <path d={BODIES[kind]} fill={color} />
      <path d={WINDOWS[kind]} fill="rgba(255,255,255,.78)" />
      <rect x={kind === "truck" ? 172 : 168} y="62" width="10" height="5" rx="2" fill="#ffd43b" />
      <rect x="12" y="64" width="7" height="5" rx="2" fill="#ff6b6b" />
      {[46, 148].map((cx) => (
        <g key={cx}>
          <circle cx={cx} cy="80" r="14" fill="#1a1b1e" />
          <circle cx={cx} cy="80" r="6.5" fill="#ced4da" />
        </g>
      ))}
      {kind === "ev" && <path d="M98 44 L92 56 L99 56 L95 66 L106 52 L99 52 L103 44 Z" fill="#fff" />}
    </svg>
  );
}
