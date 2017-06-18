clear all;
clc;

v= videoinput('winvideo',1,'YUY2_320x240');
flushdata(v);
set(v, 'ReturnedColorSpace', 'rgb');
set(v, 'TriggerRepeat', Inf);
figure;
set(gcf, 'doublebuffer', 'on');

serialport = serial('COM7');
set(serialport,'BaudRate',115200);
fopen(serialport);

angle_real = 0;
angle_measured = 0;
angle_temp = 0;
state = 0;
min_dist = Inf;
dist_measured = 0 ;
start(v);
while(1)
      data = getsnapshot(v);
      flushdata(v);
      red_im = imsubtract(data(:,:,1), rgb2gray(data));  % Empezamos a detectar los objetos rojos.
      red_im = medfilt2(red_im);             % Reducimos ruido con un filtro...
      red_im = im2bw(red_im,0.17);% Convertimos a blanco y negro para detectar en blanco el rojo...
      red_im = bwareaopen(red_im, 300);
      stats_red = regionprops(red_im, 'BoundingBox', 'Centroid');  % Medimos el centro del objeto detectado y encerramos en un cuadro el objeto...
      blue_im = imsubtract(data(:,:,3), rgb2gray(data));
      blue_im = medfilt2(blue_im);
      blue_im = im2bw(blue_im,0.13);
      blue_im = bwareaopen(blue_im, 300);
      stats_blue = regionprops(blue_im, 'BoundingBox', 'Centroid');
      red = sum(red_im(:))
      blue = sum(blue_im(:))
      imshow(data); 
      if(red > 0 && blue > 0)
          hold on 
          box_red = stats_red(1).BoundingBox;
          centroid_red = stats_red(1).Centroid;
          rectangle('Position',box_red,'EdgeColor','r','LineWidth',2);
          plot(centroid_red(1),centroid_red(2),'r*');
          box_blue = stats_blue(1).BoundingBox;
          centroid_blue = stats_blue(1).Centroid;
          rectangle('Position',box_blue,'EdgeColor','b','LineWidth',2);
          plot(centroid_blue(1),centroid_blue(2),'b*');
          %title(strcat('Angle: ', num2str(angle_real)));
          hold off
          dist_measured = sqrt((centroid_blue(2) - centroid_red(2))^2 + (centroid_blue(1) - centroid_red(1))^2);
          angle_measured = 180*atan((centroid_red(2) - centroid_blue(2))/(centroid_red(1) - centroid_blue(1)))/pi;
          if(state == 1)
              if(dist_measured > 2*min_dist)
                  disp('Ya se cumplio la distancia!!!');
              end;
              angle_real = angle_real + angle_temp - angle_measured;
              %display in serialport
              fprintf(serialport, num2str(floor(angle_real)));
              if(angle_real < 0)
                  angle_real = 0;
              elseif(angle_real >= 180)
                  angle_real = 180;    
              end;
          else
              state = 1;
          end;
          angle_temp = angle_measured;
          %fprintf(serialport, num2str(floor(angle_real)));
      else
          state = 0;
          angle_temp = 0;
          angle_measured = 0;
          min_dist = dist_measured;
      end;
      hold on
      title(strcat('Angle: ', num2str(angle_real)));
      hold off
      drawnow();
      flushdata(v);
      %fprintf(serialport, num2str(floor(angle_real)));
      %pause(0.05);
end
stop(v);
flushdata(v);
fclose(serialport);