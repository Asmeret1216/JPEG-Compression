clc; clear; close all;

% 📌 1. Load the image
image_rgb = imread('image.jpg');  % Ensure the image is in the same folder

% 📌 2. Convert to YCbCr color space
image_ycbcr = rgb2ycbcr(image_rgb);
Y  = image_ycbcr(:,:,1); % Luminance
Cb = image_ycbcr(:,:,2); % Chrominance (Blue)
Cr = image_ycbcr(:,:,3); % Chrominance (Red)

% 📌 3. Downsample Cb and Cr
Cb_down = imresize(Cb, 0.5, 'bilinear');
Cr_down = imresize(Cr, 0.5, 'bilinear');

% 📌 4. Define JPEG Quantization Table (8x8)
quant_table = [
    16 11 10 16 24 40 51 61;
    12 12 14 19 26 58 60 55;
    14 13 16 24 40 57 69 56;
    14 17 22 29 51 87 80 62;
    18 22 37 56 68 109 103 77;
    24 35 55 64 81 104 113 92;
    49 64 78 87 103 121 120 101;
    72 92 95 98 112 100 103 99];

% 📌 5. Apply DCT block-wise using `blockproc`
block_size = [8 8];

dct_y  = blockproc(double(Y),  block_size, @(block) dct2(block.data));
dct_cb = blockproc(double(Cb_down), block_size, @(block) dct2(block.data));
dct_cr = blockproc(double(Cr_down), block_size, @(block) dct2(block.data));

% 📌 6. Quantize DCT Coefficients (Fixed Size Issue)
quantized_y  = blockproc(dct_y,  block_size, @(block) round(block.data ./ quant_table(1:size(block.data,1), 1:size(block.data,2))));
quantized_cb = blockproc(dct_cb, block_size, @(block) round(block.data ./ quant_table(1:size(block.data,1), 1:size(block.data,2))));
quantized_cr = blockproc(dct_cr, block_size, @(block) round(block.data ./ quant_table(1:size(block.data,1), 1:size(block.data,2))));

% 📌 7. Dequantize (Multiply back with the quantization table)
dequantized_y  = blockproc(quantized_y,  block_size, @(block) block.data .* quant_table(1:size(block.data,1), 1:size(block.data,2)));
dequantized_cb = blockproc(quantized_cb, block_size, @(block) block.data .* quant_table(1:size(block.data,1), 1:size(block.data,2)));
dequantized_cr = blockproc(quantized_cr, block_size, @(block) block.data .* quant_table(1:size(block.data,1), 1:size(block.data,2)));

% 📌 8. Apply Inverse DCT
y_recon  = blockproc(dequantized_y,  block_size, @(block) idct2(block.data));
cb_recon = blockproc(dequantized_cb, block_size, @(block) idct2(block.data));
cr_recon = blockproc(dequantized_cr, block_size, @(block) idct2(block.data));

% 📌 9. Upsample Cb and Cr back to original size
Cb_recon_full = imresize(cb_recon, size(Cb), 'bilinear');
Cr_recon_full = imresize(cr_recon, size(Cr), 'bilinear');

% 📌 10. Reconstruct final YCbCr image and convert to RGB
recon_ycbcr = cat(3, y_recon, Cb_recon_full, Cr_recon_full);
recon_rgb = ycbcr2rgb(uint8(recon_ycbcr));

% 📌 11. Display Original and Compressed Image
figure;
subplot(1,2,1); imshow(image_rgb); title('Original Image');
subplot(1,2,2); imshow(recon_rgb); title('Compressed Image');

disp("Compression Successful! 🎉");
