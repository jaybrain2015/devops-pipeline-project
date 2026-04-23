<?php
$app_name    = getenv('APP_NAME')    ?: 'DevOps App';
$environment = getenv('APP_ENV')     ?: 'development';
$version     = getenv('APP_VERSION') ?: '1.0.0';
$db_host     = getenv('DB_HOST')     ?: 'mysql';
$db_name     = getenv('DB_NAME')     ?: 'devops_db';
$db_user     = getenv('DB_USER')     ?: 'devops_user';
$db_pass     = getenv('DB_PASS')     ?: 'devops_pass';

// Database connection
$db_status  = "disconnected";
$users      = [];
$deployments = [];

try {
    $pdo = new PDO(
        "mysql:host=$db_host;dbname=$db_name;charset=utf8",
        $db_user, $db_pass,
        [PDO::ATTR_TIMEOUT => 3, PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    $db_status   = "connected";
    $users       = $pdo->query("SELECT * FROM users ORDER BY created_at DESC")->fetchAll(PDO::FETCH_ASSOC);
    $deployments = $pdo->query("SELECT * FROM deployments ORDER BY deployed_at DESC")->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    $db_error = $e->getMessage();
}
?>
<!DOCTYPE html>
<html>
<head>
    <title><?= $app_name ?></title>
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:'Segoe UI',sans-serif; background:#0f172a; color:#e2e8f0; padding:2rem; }
        h1   { color:#38bdf8; font-size:2rem; margin-bottom:0.25rem; }
        .badge { display:inline-block; padding:0.2rem 0.75rem; border-radius:999px; font-size:0.8rem; font-weight:700; margin-bottom:1.5rem; }
        .prod { background:#dc2626; color:white; }
        .dev  { background:#16a34a; color:white; }
        .grid { display:grid; grid-template-columns:repeat(4,1fr); gap:1rem; margin-bottom:1.5rem; }
        .card { background:#1e293b; border:1px solid #334155; border-radius:0.75rem; padding:1rem; }
        .card h3 { color:#94a3b8; font-size:0.7rem; text-transform:uppercase; letter-spacing:.1em; margin-bottom:0.4rem; }
        .card p  { font-size:1rem; font-weight:600; }
        .ok  { color:#4ade80; }
        .err { color:#f87171; }
        table { width:100%; border-collapse:collapse; margin-bottom:1.5rem; }
        th    { background:#1e293b; color:#94a3b8; font-size:0.75rem; text-transform:uppercase; padding:0.75rem 1rem; text-align:left; }
        td    { padding:0.75rem 1rem; border-bottom:1px solid #1e293b; font-size:0.9rem; }
        tr:hover td { background:#1e293b; }
        .section-title { color:#94a3b8; font-size:0.75rem; text-transform:uppercase; letter-spacing:.1em; margin:1.5rem 0 0.75rem; }
        .success { color:#4ade80; } .failed { color:#f87171; }
    </style>
</head>
<body>
    <h1>�� <?= htmlspecialchars($app_name) ?></h1>
    <span class="badge <?= $environment==='production'?'prod':'dev' ?>">
        <?= strtoupper($environment) ?>
    </span>

    <div class="grid">
        <div class="card">
            <h3>Version</h3>
            <p><?= htmlspecialchars($version) ?></p>
        </div>
        <div class="card">
            <h3>PHP</h3>
            <p><?= phpversion() ?></p>
        </div>
        <div class="card">
            <h3>Database</h3>
            <p class="<?= $db_status==='connected'?'ok':'err' ?>">
                <?= $db_status==='connected'?'✅ Connected':'❌ Disconnected' ?>
            </p>
        </div>
        <div class="card">
            <h3>Container</h3>
            <p style="font-size:0.8rem;font-family:monospace"><?= gethostname() ?></p>
        </div>
    </div>

    <?php if ($db_status === 'connected'): ?>

    <p class="section-title">👤 Users in Database</p>
    <table>
        <tr><th>ID</th><th>Name</th><th>Email</th><th>Created</th></tr>
        <?php foreach ($users as $user): ?>
        <tr>
            <td><?= $user['id'] ?></td>
            <td><?= htmlspecialchars($user['name']) ?></td>
            <td><?= htmlspecialchars($user['email']) ?></td>
            <td><?= $user['created_at'] ?></td>
        </tr>
        <?php endforeach; ?>
    </table>

    <p class="section-title">🚀 Deployment History</p>
    <table>
        <tr><th>Version</th><th>Environment</th><th>Deployed By</th><th>Status</th><th>Date</th></tr>
        <?php foreach ($deployments as $d): ?>
        <tr>
            <td><?= htmlspecialchars($d['version']) ?></td>
            <td><?= htmlspecialchars($d['environment']) ?></td>
            <td><?= htmlspecialchars($d['deployed_by']) ?></td>
            <td class="<?= $d['status']==='success'?'success':'failed' ?>">
                <?= $d['status']==='success'?'✅ Success':'❌ Failed' ?>
            </td>
            <td><?= $d['deployed_at'] ?></td>
        </tr>
        <?php endforeach; ?>
    </table>

    <?php else: ?>
    <div class="card" style="margin-top:1rem">
        <h3>Database Error</h3>
        <p class="err"><?= htmlspecialchars($db_error ?? 'Cannot connect') ?></p>
    </div>
    <?php endif; ?>
</body>
</html>
