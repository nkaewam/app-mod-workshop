<?php
include 'config.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

$is_admin = ($_SESSION['role'] == 'admin');

if ($is_admin) {
    $stmt = $pdo->query("SELECT * FROM images");
} else {
    $stmt = $pdo->query("SELECT * FROM images WHERE inappropriate = 0");
}

$images = $stmt->fetchAll();
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <title>Image Catalog</title>
</head>
<body class="bg-gray-100">

<div class="container mx-auto py-8">
    <div class="flex justify-between items-center mb-4">
        <h1 class="text-2xl font-bold">Image Catalog</h1>
        <a href="upload.php" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
            Upload Image
        </a>
    </div>

    <div class="flex flex-wrap -mx-4">
        <?php foreach ($images as $image): ?>
            <div class="w-1/4 px-4 mb-4">
                <div class="bg-white rounded-lg shadow-md p-4">
                    <img src="<?php echo $image['filename']; ?>" alt="Image" class="w-full h-48 object-cover mb-2" />
                    <?php if (!empty($image['description'])): ?>
                        <p class="font-bold">Gemini Caption:</p>
                        <p class="italic"><?php echo $image['description']; ?></p>
                    <?php endif; ?>
                    <?php if ($is_admin): ?>
                        <form method="post" action="inappropriate.php">
                            <input type="hidden" name="image_id" value="<?php echo $image['id']; ?>" />
                            <button type="submit" class="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded">Mark as Inappropriate</button>
                        </form>
                    <?php endif; ?>
                </div>
            </div>
        <?php endforeach; ?>
    </div>
</div>

</body>
</html>