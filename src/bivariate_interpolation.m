#! /usr/bin/octave -qf

# Support scripts declaration
argument_checker;

function main(args)
  ##########
  # Select mode. 0 = bilinear. 1 = bicubic.
  mode = 1;
  # Select x value. x must be in [ax, bx]
  x = 3.11;
  # Select y value. y must be in [ay, by]
  y = -0.357;
  # Compression rate
  compression_rate = 5;
  #TODO: add as program parameters and make check-ups!
  ##########

  # Get arguments
  [tests_enable, image_path] = extract(args);

  # Get image
  [image_R, image_G, image_B] = get_image_matrices(image_path);

  # Compress image and save the compressed images
  printf("Compressing '%s'... ", image_path);
  [fx_R, fx_G, fx_B] = get_compressed_matrices(image_R, image_G, image_B, compression_rate);
  printf("Done!\n");

  # Write compressed images (the image itself and the 3 channels separately)
  write_compressed_images(fx_R, fx_G, fx_B);

  # Get compressed image parameters
  printf("Retrieving compressed image parameters... ");
  [nx, ny, ax, ay, bx, by, hx, hy] = get_image_parameters(fx_R);
  printf("Done!\n");

  # Compute coefficients
  [vx_R, vx_G, vx_B] = build_v(mode, fx_R, fx_G, fx_B, ax, ay, bx, by, hx, hy);

endfunction

function [vx_R, vx_G, vx_B] = build_v(mode, fx_R, fx_G, fx_B, ax, ay, bx, by, hx, hy)
  if mode == 0
    printf("Computing bilinear mode coefficients for the compressed image (\033[0;31mred channel\033[0m)... ");
    vx_R = bilinear_method(fx_R, hx, hy);
    printf("Done!\n");
    printf("Computing bilinear mode coefficients for the compressed image (\033[0;32mgreen channel\033[0m)... ");
    vx_G = bilinear_method(fx_G, hx, hy);
    printf("Done!\n");
    printf("Computing bilinear mode coefficients for the compressed image (\033[0;34mblue channel\033[0m)... ");
    vx_B = bilinear_method(fx_B, hx, hy);
    printf("Done!\n");
  else
    # Compute derivatives
    [dfx_R, dfx_G, dfx_B, dfy_R, dfy_G, dfy_B, d2fxy_R, d2fxy_G, d2fxy_B] = aproxdf(ax, ay, bx, by, hx, hy, fx_R, fx_G, fx_B);
    # Get matrices in function of h to compute coefficients for bicubic interpolation
    [mx, my] = h_matrices(hx, hy);
    printf("Computing bicubic mode coefficients for the compressed image (\033[0;31mred channel\033[0m)... ");
    vx_R = bicubic_method(fx_R, dfx_R, dfy_R, d2fxy_R, hx, hy, mx, my);
    printf("Done!\n");
    printf("Computing bicubic mode coefficients for the compressed image (\033[0;32mgreen channel\033[0m)... ");
    vx_G = bicubic_method(fx_G, dfx_G, dfy_G, d2fxy_G, hx, hy, mx, my);
    printf("Done!\n");
    printf("Computing bicubic mode coefficients for the compressed image (\033[0;34mblue channel\033[0m)... ");
    vx_B = bicubic_method(fx_B, dfx_B, dfy_B, d2fxy_B, hx, hy, mx, my);
    printf("Done!\n");
  endif
endfunction

# Compute bilinear method's coefficients
function vx = bilinear_method(fx, hx, hy)
  row = rows(fx);
  while row > 1
    column = 1;
    while column < columns(fx)
      vx(row - 1, column).c0 = fx(row, column);
      vx(row - 1, column).c1 = (fx(row, column + 1) - vx(row - 1, column).c0) / hx;
      vx(row - 1, column).c2 = (fx(row - 1, column) - vx(row - 1, column).c0) / hy;
      vx(row - 1, column).c3 = (fx(row - 1, column + 1) - vx(row - 1, column).c0 - (hx * vx(row - 1, column).c1) - (hy * vx(row - 1, column).c2)) / (hx * hy);
      column++;
    endwhile
    row--;
  endwhile
endfunction

# Compute bicubic method's coefficients
function vx = bicubic_method(fx, dfx, dfy, d2fxy, hx, hy, mx, my)
  row = rows(fx);
  while row > 1
    column = 1;
    while column < columns(fx)

      mh = [
          fx(row, column),      fx(row - 1, column),      dfy(row, column),       dfy(row - 1, column);
          fx(row, column + 1),  fx(row - 1, column + 1),  dfy(row, column + 1),   dfy(row - 1, column + 1);
          dfx(row, column),     dfx(row - 1, column),     d2fxy(row, column),     d2fxy(row - 1, column);
          dfx(row, column + 1), dfx(row - 1, column + 1), d2fxy(row, column + 1), d2fxy(row - 1, column + 1);
        ];
      mh = double(mh);
      coefficients = mx * mh * my;

      vx(row - 1, column).c0  = coefficients(1, 1);
      vx(row - 1, column).c1  = coefficients(1, 2);
      vx(row - 1, column).c2  = coefficients(1, 3);
      vx(row - 1, column).c3  = coefficients(1, 4);
      vx(row - 1, column).c4  = coefficients(2, 1);
      vx(row - 1, column).c5  = coefficients(2, 2);
      vx(row - 1, column).c6  = coefficients(2, 3);
      vx(row - 1, column).c7  = coefficients(2, 4);
      vx(row - 1, column).c8  = coefficients(3, 1);
      vx(row - 1, column).c9  = coefficients(3, 2);
      vx(row - 1, column).c10 = coefficients(3, 3);
      vx(row - 1, column).c11 = coefficients(3, 4);
      vx(row - 1, column).c12 = coefficients(4, 1);
      vx(row - 1, column).c13 = coefficients(4, 2);
      vx(row - 1, column).c14 = coefficients(4, 3);
      vx(row - 1, column).c15 = coefficients(4, 4);
      column++;
    endwhile
    row--;
  endwhile
endfunction

# Compute matrices used to compute the coefficients
function [mx, my] = h_matrices(hx, hy)
  mx = [
    1.0,                   0.0,                  0.0,             0.0;
    0.0,                   0.0,                  1.0,             0.0;
   -3.0 / (hx * hx),       3.0 / (hx * hx),     -2.0 / hx,       -1.0 / hx;
    2.0 / (hx * hx * hx), -2.0 / (hx * hx * hx), 1.0 / (hx * hx), 1.0 / (hx * hx)
  ];
  my = [
    1.0, 0.0, -3.0 / (hy * hy),  2.0 / (hy * hy * hy);
    0.0, 0.0,  3.0 / (hy * hy), -2.0 / (hy * hy * hy);
    0.0, 1.0, -2.0 / hy,         1.0 / (hy * hy);
    0.0, 0.0, -1.0 / hy,         1.0 / (hy * hy)
  ];
endfunction

function [dfx_R, dfx_G, dfx_B, dfy_R, dfy_G, dfy_B, d2fxy_R, d2fxy_G, d2fxy_B] = aproxdf(ax, ay, bx, by, hx, hy, fx_R, fx_G, fx_B)
  # dfx
  printf("Computing partial derivative on x (dfx) for the compressed image (\033[0;31mred channel\033[0m)... ");
  dfx_R = compute_dfx(ax, ay, bx, by, hx, hy, fx_R);
  printf("Done!\n");
  printf("Computing partial derivative on x (dfx) for the compressed image (\033[0;32mgreen channel\033[0m)... ");
  dfx_G = compute_dfx(ax, ay, bx, by, hx, hy, fx_G);
  printf("Done!\n");
  printf("Computing partial derivative on x (dfx) for the compressed image (\033[0;34mblue channel\033[0m)... ");
  dfx_B = compute_dfx(ax, ay, bx, by, hx, hy, fx_B);
  printf("Done!\n");

  # dfy
  printf("Computing partial derivative on y (dfy) for the compressed image (\033[0;31mred channel\033[0m)... ");
  dfy_R = compute_dfy(ax, ay, bx, by, hx, hy, fx_R);
  printf("Done!\n");
  printf("Computing partial derivative on y (dfy) for the compressed image (\033[0;32mgreen channel\033[0m)... ");
  dfy_G = compute_dfy(ax, ay, bx, by, hx, hy, fx_G);
  printf("Done!\n");
  printf("Computing partial derivative on y (dfy) for the compressed image (\033[0;34mblue channel\033[0m)... ");
  dfy_B = compute_dfy(ax, ay, bx, by, hx, hy, fx_B);
  printf("Done!\n");

  # d2fxy
  printf("Computing mixed derivatives (d2fxy) for the compressed image (\033[0;31mred channel\033[0m)... ");
  d2fxy_R = compute_d2fxy(ax, ay, bx, by, hx, hy, dfy_R);
  printf("Done!\n");
  printf("Computing mixed derivatives (d2fxy) for the compressed image (\033[0;32mgreen channel\033[0m)... ");
  d2fxy_G = compute_d2fxy(ax, ay, bx, by, hx, hy, dfy_G);
  printf("Done!\n");
  printf("Computing mixed derivatives (d2fxy) for the compressed image (\033[0;34mblue channel\033[0m)... ");
  d2fxy_B = compute_d2fxy(ax, ay, bx, by, hx, hy, dfy_B);
  printf("Done!\n");
endfunction

# Compute d2fxy
function d2fxy = compute_d2fxy(ax, ay, bx, by, hx, hy, dfy)
  d2fxy = [];

  row = rows(dfy);
  while row >= 1
    column = 1;
    new_row = [];
    while column <= columns(dfy)
      if left_border_pixel(ax, column)
        new_row = [new_row, (dfy(row, column + 1) - dfy(row, column)) / hx];
      elseif right_border_pixel(bx, column)
        new_row = [new_row, (dfy(row, column) - dfy(row, column - 1)) / hx];
      else
        new_row = [new_row, (dfy(row, column + 1) - dfy(row, column - 1)) / (2 * hx)];
      endif
      column++;
    endwhile
    row--;
    d2fxy = [new_row; d2fxy];
  endwhile
endfunction

# Compute dfy
function dfy = compute_dfy(ax, ay, bx, by, hx, hy, fx)
  dfy = [];

  row = rows(fx);
  while row >= 1
    column = 1;
    new_row = [];
    while column <= columns(fx)
      if bot_border_pixel(ay, row)
        new_row = [new_row, (fx(row + 1, column) - fx(row, column)) / hy];
      elseif top_border_pixel(by, row)
        new_row = [new_row, (fx(row, column) - fx(row - 1, column)) / hy];
      else
        new_row = [new_row, (fx(row + 1, column) - fx(row - 1, column)) / (2 * hy)];
      endif
      column++;
    endwhile
    row--;
    dfy = [new_row; dfy];
  endwhile
endfunction

# Compute dfx
function dfx = compute_dfx(ax, ay, bx, by, hx, hy, fx)
  dfx = [];

  row = rows(fx);
  while row >= 1
    column = 1;
    new_row = [];
    while column <= columns(fx)
      if left_border_pixel(ax, column)
        new_row = [new_row, (fx(row, column + 1) - fx(row, column)) / hx];
      elseif right_border_pixel(bx, column)
        new_row = [new_row, (fx(row, column) - fx(row, column - 1)) / hx];
      else
        new_row = [new_row, (fx(row, column + 1) - fx(row, column - 1)) / (2 * hx)];
      endif
      column++;
    endwhile
    row--;
    dfx = [new_row; dfx];
  endwhile
endfunction

# Is the pixel part of the left border?
function value = left_border_pixel(ax, column)
  value = (column == ax + 1);
endfunction

# Is the pixel part of the right border?
function value = right_border_pixel(bx, column)
  value = (column == bx);
endfunction

# Is the pixel part of the bot border?
function value = bot_border_pixel(ay, row)
  value = (row == ay + 1);
endfunction

# Is the pixel part of the top border?
function value = top_border_pixel(by, row)
  value = (row == by);
endfunction

# Write compressed images
function write_compressed_images(fx_R, fx_G, fx_B)
  printf("Writing compressed image (\033[0;31mred channel\033[0m) to 'images/compressed_red.jpg'.\n");
  imwrite(fx_R, "../images/compressed_red.jpg");
  printf("Writing compressed image (\033[0;32mgreen channel\033[0m) to 'images/compressed_green.jpg'.\n");
  imwrite(fx_G, "../images/compressed_green.jpg");
  printf("Writing compressed image (\033[0;34mblue channel\033[0m) to 'images/compressed_blue.jpg'.\n");
  imwrite(fx_B, "../images/compressed_blue.jpg");
endfunction

# Get compressed image matrices
function [fx_R, fx_G, fx_B] = get_compressed_matrices(image_R, image_G, image_B, compression_rate)
  fx_R = compress(image_R, compression_rate);
  fx_G = compress(image_G, compression_rate);
  fx_B = compress(image_B, compression_rate);
endfunction

# Compress image using the compression rate parameter
function fx = compress(image_, compression_rate)
  fx = [];
  [nx, ny, ax, ay, bx, by, hx, hy] = get_image_parameters(image_);

  row = rows(image_);
  while row >= 1
    if rem(row, compression_rate) == 0 && !bot_border_pixel(ay, row) && !top_border_pixel(by, row)
      row--;
      continue;
    endif

    column = 1;
    new_row = [];
    while column <= columns(image_)
      if rem(column, compression_rate) == 0 && !left_border_pixel(ax, column) && !right_border_pixel(bx, column)
        column++;
        continue;
      endif
      new_row = [new_row, image_(row, column)];
      column++;
    endwhile
    row--;
    fx = [new_row; fx];
  endwhile
endfunction

# Get image parameters
function [nx, ny, ax, ay, bx, by, hx, hy] = get_image_parameters(image_)
  ax = 0;
  ay = 0;
  bx = columns(image_);
  by = rows(image_);
  nx = bx - ax;
  ny = by - ay;
  hx = (bx - ax) / nx; # = 1 for the image
  hy = (by - ay) / ny; # = 1 for the image
endfunction

# Get image and its RGB channels matircs
function [image_R, image_G, image_B] = get_image_matrices(image_path)
  image_ = imread(image_path);
  image_R = image_(:,:,1);
  image_G = image_(:,:,2);
  image_B = image_(:,:,3);
endfunction



main(argv());





#fx = reshape(1:(rows(fx_R) * columns(fx_R) * 3), rows(fx_R), columns(fx_R), 3);
#fx(:,:,1) = fx_R;
#fx(:,:,2) = fx_G;
#fx(:,:,3) = fx_B;
