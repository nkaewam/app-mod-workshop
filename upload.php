<?php
include 'config.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

$message = '';
$message_type = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_FILES['image'])) {
    $filename = 'uploads/' . basename($_FILES['image']['name']);
    if (move_uploaded_file($_FILES['image']['tmp_name'], $filename)) {
        $stmt = $pdo->prepare("INSERT INTO images (user_id, filename) VALUES (?, ?)");
        $stmt->execute([$_SESSION['user_id'], $filename]);
        $message = "Image uploaded successfully! <a href='index.php' class='underline'>Go back to catalog</a>.";
        $message_type = 'success';
    } else {
        $message = "Error uploading the image.";
        $message_type = 'error';
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <title>Upload Image</title>
</head>
<body class="bg-gray-100">

<div class="container mx-auto py-8">
    <div class="max-w-md mx-auto bg-white rounded-lg shadow-md p-6">
        <h1 class="text-2xl font-bold mb-4">Upload a New Image</h1>

        <?php if ($message): ?>
            <div class="<?php echo $message_type == 'success' ? 'bg-green-100 border-green-400 text-green-700' : 'bg-red-100 border-red-400 text-red-700'; ?> border px-4 py-3 rounded relative mb-4" role="alert">
                <span class="block sm:inline"><?php echo $message; ?></span>
            </div>
        <?php endif; ?>

        <form method="post" enctype="multipart/form-data">
            <div class="mb-4">
                <input type="file" name="image" required class="w-full px-3 py-2 border rounded-lg" />
            </div>
            <button type="submit" class="w-full bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Upload Image</button>
        </form>
    </div>
</div>

</body>
</html>