// The render-target pool now lives in laplaceliu/tycho/pool so tycho_2d and
// tycho_3d share one implementation (roadmap/tycho-3d-design.md, R-POOL).
// Kept as a public alias so existing tycho_2d users see no API change.

///|
pub type RenderTargetPool = @pool.RenderTargetPool
